#!/usr/bin/env python3
"""ui-forge live mode — HTTP+WebSocket reverse proxy with overlay injection.

Sits in front of an existing dev server (Vite/Next/Rails/etc.), forwards every
HTTP and WebSocket request to it, and (in later waves) injects overlay.js into
HTML responses + intercepts POST /forge/feedback to write pin JSON files into
.ui-forge/live/<session-id>/.

Run from the project root (parent of .ui-forge/):
    python3 live.py --target http://localhost:3000 [--port 4270] [--name <slug>]

Wave 1 deliverable: HTTP passthrough only (no HTML injection, no WS, no
feedback intercept, no static endpoints — those are added in waves 2-5).
"""

from __future__ import annotations

import argparse
import asyncio
import json
import os
import re
import signal
import sys
import time
from pathlib import Path
from urllib.parse import urlparse

import aiohttp
from aiohttp import web

DEFAULT_PORT = 4270

INJECT_START = "<!-- ui-forge:live:injected:start -->"
INJECT_END = "<!-- ui-forge:live:injected:end -->"

SESSION_ID_RE = re.compile(r"^[A-Za-z0-9._:\-]{1,64}$")

TARGET_KEY: web.AppKey[str] = web.AppKey("target", str)
TARGET_HOST_KEY: web.AppKey[str] = web.AppKey("target_host", str)
SESSION_ID_KEY: web.AppKey[str] = web.AppKey("session_id", str)
CLIENT_SESSION_KEY: web.AppKey[aiohttp.ClientSession] = web.AppKey("client_session", aiohttp.ClientSession)
ACTIVE_WS_KEY: web.AppKey[set] = web.AppKey("active_ws", set)

HOP_BY_HOP_REQUEST_HEADERS = {
    "host",
    "connection",
    "keep-alive",
    "proxy-authenticate",
    "proxy-authorization",
    "te",
    "trailers",
    "transfer-encoding",
    "upgrade",
    "content-length",  # aiohttp recomputes
}
HOP_BY_HOP_RESPONSE_HEADERS = {
    "connection",
    "keep-alive",
    "proxy-authenticate",
    "proxy-authorization",
    "te",
    "trailers",
    "transfer-encoding",
    "upgrade",
    "content-length",  # aiohttp recomputes
    "content-encoding",  # aiohttp decoded the body, do not claim original encoding
}


# ---------------------------------------------------------------------------
# App lifecycle
# ---------------------------------------------------------------------------

async def build_app(target: str, session_id: str) -> web.Application:
    """Create the proxy aiohttp Application.

    Exposed for tests (conftest.live_proxy fixture wraps this in a TestServer).
    """
    parsed = urlparse(target)
    target_host = parsed.netloc

    app = web.Application()
    app[TARGET_KEY] = target.rstrip("/")
    app[TARGET_HOST_KEY] = target_host
    app[SESSION_ID_KEY] = session_id
    app[CLIENT_SESSION_KEY] = aiohttp.ClientSession()
    app[ACTIVE_WS_KEY] = set()

    # Specific routes BEFORE the catch-all so they intercept matching paths.
    app.router.add_get("/forge/__overlay.js", _serve_overlay)
    app.router.add_post("/forge/feedback", _handle_feedback)

    # Catch-all proxy handler — every other path goes upstream.
    app.router.add_route("*", "/{path:.*}", _proxy_handler)
    return app


async def shutdown_app(app: web.Application) -> None:
    """Close shared resources. Safe to call multiple times.

    Closes every tracked active WebSocketResponse first so their pump tasks
    unblock from `async for msg in ...` and exit; then closes the shared
    ClientSession. Without this, runner.cleanup() blocks forever on quiet
    WebSocket pumps that never receive a CLOSE frame from either peer.
    """
    active_ws = app.get(ACTIVE_WS_KEY)
    if active_ws:
        for ws in list(active_ws):
            if not ws.closed:
                try:
                    await asyncio.wait_for(
                        ws.close(code=1001, message=b"server shutting down"),
                        timeout=1.0,
                    )
                except (asyncio.TimeoutError, Exception):
                    pass
        active_ws.clear()

    session = app.get(CLIENT_SESSION_KEY)
    if session is not None and not session.closed:
        await session.close()


# ---------------------------------------------------------------------------
# Static endpoints (served locally, never proxied)
# ---------------------------------------------------------------------------

async def _serve_overlay(request: web.Request) -> web.Response:
    """Serve overlay.js from <project>/.ui-forge/assets/overlay.js."""
    overlay_path = Path.cwd() / ".ui-forge" / "assets" / "overlay.js"
    try:
        body = overlay_path.read_bytes()
    except FileNotFoundError:
        return web.Response(
            status=503,
            text=(
                "[ui-forge] overlay.js not found at .ui-forge/assets/overlay.js"
                " — run init-registry.sh first"
            ),
        )
    return web.Response(
        body=body,
        content_type="application/javascript",
    )


# ---------------------------------------------------------------------------
# HTML injection
# ---------------------------------------------------------------------------

def _build_init_block(session_id: str, host: str, path: str) -> str:
    """The <script> block injected before </body> in HTML responses."""
    return (
        f"{INJECT_START}\n"
        f"<script>\n"
        f"  window.UIFORGE_MODE = {json.dumps('live')};\n"
        f"  window.UIFORGE_SESSION_ID = {json.dumps(session_id)};\n"
        f"  window.UIFORGE_LIVE_HOST = {json.dumps(host)};\n"
        f"  window.UIFORGE_LIVE_PATH = {json.dumps(path)};\n"
        f"  window.UIFORGE_FEEDBACK_URL = {json.dumps('/forge/feedback')};\n"
        f"</script>\n"
        f"<script src=\"/forge/__overlay.js\" defer></script>\n"
        f"{INJECT_END}\n"
    )


def _inject_overlay(html: str, session_id: str, host: str, path: str) -> str:
    """Insert the overlay init block before the last </body> tag.

    Idempotent: if the marker is already present, returns html unchanged so
    retries / cached responses do not stack multiple injections.

    If the document has no </body>, the block is appended at the end and a
    warning is printed to stderr (rare in practice — most frameworks emit
    well-formed HTML).
    """
    if INJECT_START in html:
        return html

    block = _build_init_block(session_id, host, path)

    # rfind on the lowercased copy to locate </body> case-insensitively
    # while keeping the original casing in the output.
    lowered = html.lower()
    idx = lowered.rfind("</body>")
    if idx == -1:
        print(
            f"[ui-forge] warning: no </body> in response for {path} — overlay appended at end",
            file=sys.stderr,
            flush=True,
        )
        return html + block

    return html[:idx] + block + html[idx:]


# ---------------------------------------------------------------------------
# HTTP passthrough
# ---------------------------------------------------------------------------

async def _proxy_handler(request: web.Request) -> web.StreamResponse:
    """Forward HTTP (or WebSocket) request to upstream and stream the response back."""
    target = request.app[TARGET_KEY]
    target_host = request.app[TARGET_HOST_KEY]
    session_id = request.app[SESSION_ID_KEY]
    session = request.app[CLIENT_SESSION_KEY]

    if request.headers.get("Upgrade", "").lower() == "websocket":
        return await _proxy_websocket(request, target, session)

    upstream_url = target + request.rel_url.path_qs
    forwarded_headers = {
        k: v for k, v in request.headers.items()
        if k.lower() not in HOP_BY_HOP_REQUEST_HEADERS
    }

    body = await request.read()

    async with session.request(
        method=request.method,
        url=upstream_url,
        headers=forwarded_headers,
        data=body,
        allow_redirects=False,
    ) as upstream_resp:
        response_body = await upstream_resp.read()
        response_headers = {
            k: v for k, v in upstream_resp.headers.items()
            if k.lower() not in HOP_BY_HOP_RESPONSE_HEADERS
        }

        content_type = upstream_resp.headers.get("Content-Type", "")
        if content_type.lower().startswith("text/html"):
            try:
                charset = upstream_resp.charset or "utf-8"
                html = response_body.decode(charset)
                injected = _inject_overlay(html, session_id, target_host, request.rel_url.path)
                response_body = injected.encode(charset)
            except UnicodeDecodeError:
                # Body claimed text/html but isn't decodable — pass through raw.
                pass

        return web.Response(
            status=upstream_resp.status,
            headers=response_headers,
            body=response_body,
        )


# ---------------------------------------------------------------------------
# Feedback intercept
# ---------------------------------------------------------------------------

async def _handle_feedback(request: web.Request) -> web.Response:
    """Persist a feedback round to .ui-forge/live/<session-id>/round-NN.json.

    Validates payload shape, writes round-NN.json + latest.json, prints
    a one-line stdout trigger that Monitor surfaces as a single event.
    Never proxied — this route is registered before the catch-all.
    """
    try:
        body = await request.read()
        payload = json.loads(body)
    except (json.JSONDecodeError, UnicodeDecodeError) as e:
        return web.json_response({"error": f"invalid JSON: {e}"}, status=400)

    session_id = payload.get("sessionId")
    if not session_id or not isinstance(session_id, str):
        return web.json_response({"error": "missing sessionId"}, status=400)
    if not SESSION_ID_RE.match(session_id):
        return web.json_response(
            {"error": f"invalid sessionId: {session_id!r}"}, status=400
        )

    round_num = int(payload.get("round", 1))
    pin_count = int(payload.get("pinCount", 0))
    host = payload.get("host", "")
    path = payload.get("path", "")
    new_ids = set(payload.get("newPinIds", []) or [])
    all_pins = payload.get("pins", []) or []
    new_pins = [p for p in all_pins if p.get("id") in new_ids] or all_pins

    feedback_dir = Path.cwd() / ".ui-forge" / "live" / session_id
    feedback_dir.mkdir(parents=True, exist_ok=True)

    filename = f"round-{round_num:02d}.json"
    (feedback_dir / filename).write_text(json.dumps(payload, indent=2))
    (feedback_dir / "latest.json").write_text(json.dumps({
        "file": filename,
        "sessionId": session_id,
        "host": host,
        "path": path,
        "round": round_num,
        "pinCount": pin_count,
        "receivedAt": time.strftime("%Y-%m-%dT%H:%M:%S"),
    }, indent=2))

    print(
        _format_feedback_line(session_id, round_num, host, path, pin_count, new_pins),
        flush=True,
    )

    return web.json_response({"ok": True, "file": filename})


def _one_line(value: str | None, limit: int) -> str:
    s = " ".join((value or "").split())
    if len(s) > limit:
        s = s[:limit] + "…"
    return s


def _format_feedback_line(
    session_id: str,
    round_num: int,
    host: str,
    path: str,
    pin_count: int,
    new_pins: list,
) -> str:
    """Single-line Monitor trigger for live-mode feedback.

    Mirrors prototype mode's `_format_feedback_line` but adds session/host/path
    and points at show-pin-live.py instead of show-pin.py.
    """
    segments = []
    for p in new_pins:
        pid = p.get("id")
        ptype = p.get("type", "change")
        region = p.get("region")
        if region:
            loc = f"{region.get('w')}x{region.get('h')}@({region.get('x')},{region.get('y')})"
        else:
            loc = f"@({p.get('x')},{p.get('y')})"
        comment = _one_line(p.get("comment"), 140).replace("|", "/")
        segments.append(f"#{pid}[{ptype}] {loc} \"{comment}\"")
    pins_part = " || ".join(segments) if segments else "(no new pins)"
    return (
        f"[ui-forge] live round={round_num} session={session_id} "
        f"host={host} path={path} new={len(new_pins)} total={pin_count} | "
        f"{pins_part} | details: show-pin-live.py {session_id} --round {round_num}"
    )


# ---------------------------------------------------------------------------
# WebSocket proxy
# ---------------------------------------------------------------------------

WS_FORWARD_DROP = {
    "host", "connection", "upgrade", "sec-websocket-key",
    "sec-websocket-version", "sec-websocket-extensions",
    "sec-websocket-accept",
}


async def _proxy_websocket(
    request: web.Request,
    target: str,
    session: aiohttp.ClientSession,
) -> web.WebSocketResponse:
    """Bridge a client WebSocket to the upstream's WebSocket of the same path."""
    ws_server = web.WebSocketResponse()
    await ws_server.prepare(request)
    request.app[ACTIVE_WS_KEY].add(ws_server)

    # Translate http(s):// → ws(s):// for the upstream URL.
    upstream_base = target.replace("http://", "ws://", 1).replace("https://", "wss://", 1)
    upstream_url = upstream_base + request.rel_url.path_qs

    forwarded_headers = {
        k: v for k, v in request.headers.items()
        if k.lower() not in WS_FORWARD_DROP
    }

    try:
        ws_client = await session.ws_connect(
            upstream_url,
            headers=forwarded_headers,
            autoping=False,
            heartbeat=None,
        )
    except aiohttp.ClientError as e:
        await ws_server.close(code=1011, message=f"upstream WS connect failed: {e}".encode())
        return ws_server

    async def pump(src: aiohttp.ClientWebSocketResponse | web.WebSocketResponse,
                   dst: aiohttp.ClientWebSocketResponse | web.WebSocketResponse) -> None:
        try:
            async for msg in src:
                if msg.type == aiohttp.WSMsgType.TEXT:
                    await dst.send_str(msg.data)
                elif msg.type == aiohttp.WSMsgType.BINARY:
                    await dst.send_bytes(msg.data)
                elif msg.type == aiohttp.WSMsgType.PING:
                    await dst.ping(msg.data)
                elif msg.type == aiohttp.WSMsgType.PONG:
                    await dst.pong(msg.data)
                elif msg.type in (aiohttp.WSMsgType.CLOSE, aiohttp.WSMsgType.CLOSING, aiohttp.WSMsgType.CLOSED):
                    break
                elif msg.type == aiohttp.WSMsgType.ERROR:
                    break
        except Exception:
            pass
        finally:
            # When one side dies, tear down the other so its pump exits too.
            # Bounded so a misbehaving peer cannot stall shutdown indefinitely.
            if not dst.closed:
                try:
                    await asyncio.wait_for(dst.close(), timeout=1.0)
                except (asyncio.TimeoutError, Exception):
                    pass

    task_c2u = asyncio.create_task(pump(ws_server, ws_client))
    task_u2c = asyncio.create_task(pump(ws_client, ws_server))

    done, pending = await asyncio.wait(
        {task_c2u, task_u2c}, return_when=asyncio.FIRST_COMPLETED
    )
    for t in pending:
        t.cancel()
    for t in pending:
        try:
            await t
        except (asyncio.CancelledError, Exception):
            pass

    for w in (ws_client, ws_server):
        if not w.closed:
            try:
                await asyncio.wait_for(w.close(), timeout=1.0)
            except (asyncio.TimeoutError, Exception):
                pass
    request.app[ACTIVE_WS_KEY].discard(ws_server)
    return ws_server


# ---------------------------------------------------------------------------
# CLI / main()
# ---------------------------------------------------------------------------

def _default_session_id() -> str:
    return time.strftime("%Y-%m-%dT%H%M%S")


def _parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="ui-forge-live",
        description="Reverse proxy that injects the ui-forge overlay into an existing dev server's responses.",
    )
    parser.add_argument(
        "--target",
        required=True,
        help="Upstream dev server URL (e.g. http://localhost:3000).",
    )
    parser.add_argument(
        "--port",
        type=int,
        default=DEFAULT_PORT,
        help=f"Local port for the proxy (default: {DEFAULT_PORT}). Use 0 to let the OS pick.",
    )
    parser.add_argument(
        "--name",
        default=None,
        help="Session slug — directory name under .ui-forge/live/. Defaults to ISO timestamp.",
    )
    return parser.parse_args(argv)


def _resolve_uiforge_root() -> Path:
    uiforge = Path.cwd() / ".ui-forge"
    if not uiforge.is_dir():
        print(
            f"[ui-forge] error: {uiforge} does not exist. Run init-registry.sh first.",
            file=sys.stderr,
            flush=True,
        )
        sys.exit(1)
    return uiforge


def _write_pid(pid_file: Path) -> None:
    pid_file.write_text(str(os.getpid()))


def _remove_pid(pid_file: Path) -> None:
    pid_file.unlink(missing_ok=True)


async def _serve(app: web.Application, host: str, port: int, target: str, session_id: str, pid_file: Path) -> None:
    runner = web.AppRunner(app, access_log=None)
    await runner.setup()
    site = web.TCPSite(runner, host, port)
    await site.start()

    # Read the actual bound port (handles --port 0).
    sockets = list(site._server.sockets) if site._server is not None else []
    actual_port = sockets[0].getsockname()[1] if sockets else port

    _write_pid(pid_file)
    print(
        f"[ui-forge] live serving http://{host}:{actual_port} → {target} (session={session_id})",
        flush=True,
    )

    stop_event = asyncio.Event()
    loop = asyncio.get_running_loop()

    def _signal_handler() -> None:
        stop_event.set()

    for sig in (signal.SIGTERM, signal.SIGINT):
        try:
            loop.add_signal_handler(sig, _signal_handler)
        except NotImplementedError:
            # Windows fallback — not relevant here but keep robust.
            signal.signal(sig, lambda *_: stop_event.set())

    try:
        await stop_event.wait()
    finally:
        # Close active WS + shared client session BEFORE cleaning up the
        # runner — otherwise runner.cleanup blocks on quiet WS pumps.
        try:
            await asyncio.wait_for(shutdown_app(app), timeout=3.0)
        except asyncio.TimeoutError:
            pass
        try:
            await asyncio.wait_for(runner.cleanup(), timeout=3.0)
        except asyncio.TimeoutError:
            pass
        _remove_pid(pid_file)


def main(argv: list[str] | None = None) -> int:
    args = _parse_args(argv)
    uiforge = _resolve_uiforge_root()
    session_id = args.name or _default_session_id()
    pid_file = uiforge / ".live-server.pid"

    async def _run() -> None:
        app = await build_app(target=args.target, session_id=session_id)
        await _serve(app, "127.0.0.1", args.port, args.target, session_id, pid_file)

    try:
        asyncio.run(_run())
    except KeyboardInterrupt:
        # Already handled via signal handler, but be defensive.
        _remove_pid(pid_file)
    return 0


if __name__ == "__main__":
    sys.exit(main())
