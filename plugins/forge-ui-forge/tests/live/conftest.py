"""Shared fixtures for live-mode tests.

Provides:
    stub_upstream  — a small aiohttp app simulating a real dev server
                     (HTML, JSON, JS, /api/echo POST, /ws WebSocket echo).
    tmp_uiforge    — a temp .ui-forge/ directory + cwd switched to its parent.
    live_proxy     — a TestClient wrapping live.py's aiohttp Application
                     pointed at the stub_upstream.
"""

from __future__ import annotations

import asyncio
import importlib.util
import os
import sys
from pathlib import Path

import pytest

aiohttp = pytest.importorskip("aiohttp")
from aiohttp import web  # noqa: E402
from aiohttp.test_utils import TestServer, TestClient  # noqa: E402

PLUGIN_ROOT = Path(__file__).resolve().parents[2]
LIVE_DIR = PLUGIN_ROOT / "skills" / "ui-forge" / "scripts" / "live"


def _load_live_module():
    """Import live.py by absolute path so the test does not depend on cwd."""
    live_path = LIVE_DIR / "live.py"
    if not live_path.exists():
        pytest.skip(f"live.py not yet implemented at {live_path}")
    spec = importlib.util.spec_from_file_location("ui_forge_live", live_path)
    module = importlib.util.module_from_spec(spec)
    sys.modules["ui_forge_live"] = module
    spec.loader.exec_module(module)
    return module


# ---------------------------------------------------------------------------
# Stub upstream
# ---------------------------------------------------------------------------

class UpstreamRecorder:
    """Tracks active WS connections and HTTP request paths for assertions."""

    def __init__(self) -> None:
        self.requests: list[tuple[str, str]] = []  # (method, path)
        self.active_ws: set[web.WebSocketResponse] = set()


@pytest.fixture
async def stub_upstream():
    """An aiohttp app simulating a generic dev server.

    Routes:
        GET  /index.html           text/html with <html><body>...</body></html>
        GET  /api/data             application/json with a fixed payload
        GET  /static/app.js        application/javascript
        POST /api/echo             echoes back the JSON body
        GET  /ws                   WebSocket echo (records connection in recorder)

    Yields (base_url: str, recorder: UpstreamRecorder).
    """
    recorder = UpstreamRecorder()

    async def index(request: web.Request) -> web.Response:
        recorder.requests.append((request.method, request.path))
        return web.Response(
            text="<!doctype html><html><body><div id=\"app\">upstream</div></body></html>",
            content_type="text/html",
        )

    async def api_data(request: web.Request) -> web.Response:
        recorder.requests.append((request.method, request.path))
        return web.json_response({"hello": "from upstream", "n": 42})

    async def static_js(request: web.Request) -> web.Response:
        recorder.requests.append((request.method, request.path))
        return web.Response(
            text="console.log('upstream js');",
            content_type="application/javascript",
        )

    async def api_echo(request: web.Request) -> web.Response:
        recorder.requests.append((request.method, request.path))
        body = await request.json()
        return web.json_response({"echo": body})

    async def ws_echo(request: web.Request) -> web.WebSocketResponse:
        recorder.requests.append((request.method, request.path))
        ws = web.WebSocketResponse()
        await ws.prepare(request)
        recorder.active_ws.add(ws)
        try:
            async for msg in ws:
                if msg.type == aiohttp.WSMsgType.TEXT:
                    await ws.send_str(msg.data)
                elif msg.type == aiohttp.WSMsgType.BINARY:
                    await ws.send_bytes(msg.data)
                elif msg.type == aiohttp.WSMsgType.CLOSE:
                    break
        finally:
            recorder.active_ws.discard(ws)
        return ws

    app = web.Application()
    app.router.add_get("/index.html", index)
    app.router.add_get("/api/data", api_data)
    app.router.add_get("/static/app.js", static_js)
    app.router.add_post("/api/echo", api_echo)
    app.router.add_get("/ws", ws_echo)
    # catch-all so recorder still tracks unknown paths
    async def fallback(request: web.Request) -> web.Response:
        recorder.requests.append((request.method, request.path))
        return web.Response(status=404, text="upstream-404")
    app.router.add_route("*", "/{path:.*}", fallback)

    server = TestServer(app)
    await server.start_server()
    base_url = f"http://{server.host}:{server.port}"
    try:
        yield base_url, recorder
    finally:
        # Close any WebSockets the upstream still considers active so close()
        # below does not block on lingering half-open connections.
        for ws in list(recorder.active_ws):
            if not ws.closed:
                try:
                    await asyncio.wait_for(ws.close(), timeout=0.5)
                except (asyncio.TimeoutError, Exception):
                    pass
        recorder.active_ws.clear()
        await server.close()


# ---------------------------------------------------------------------------
# tmp .ui-forge/
# ---------------------------------------------------------------------------

@pytest.fixture
def tmp_uiforge(tmp_path, monkeypatch):
    """Create tmp_path/.ui-forge/ and chdir into tmp_path.

    live.py reads `Path.cwd() / ".ui-forge"` so the cwd switch is essential.
    """
    uiforge = tmp_path / ".ui-forge"
    uiforge.mkdir()
    (uiforge / "assets").mkdir()
    monkeypatch.chdir(tmp_path)
    return uiforge


# ---------------------------------------------------------------------------
# live_proxy TestClient
# ---------------------------------------------------------------------------

@pytest.fixture
async def live_proxy(stub_upstream, tmp_uiforge):
    """Builds the live.py aiohttp Application pointed at the stub upstream."""
    base_url, recorder = stub_upstream
    live = _load_live_module()
    app = await live.build_app(target=base_url, session_id="test-session")
    server = TestServer(app)
    client = TestClient(server)
    await client.start_server()
    try:
        yield client, base_url, recorder
    finally:
        await client.close()
        await live.shutdown_app(app)
