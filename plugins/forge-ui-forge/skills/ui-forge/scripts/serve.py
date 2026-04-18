#!/usr/bin/env python3
"""
ui-forge dev server — serves .ui-forge/ with hot-reload SSE + feedback POST.

Run from the project root (parent of .ui-forge/):
    python3 <path>/serve.py [port]

Endpoints:
    GET  /*                  static files from .ui-forge/
    POST /forge/feedback     writes round-NN.json, prints trigger to stdout (Monitor)
    GET  /forge/reload       SSE — sends "reload" when any 02-forge.html changes
"""

import http.server
import json
import os
import re
import signal
import sys
import threading
import time
from pathlib import Path

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 4269
PROJECT_ROOT = Path.cwd()
UI_FORGE = PROJECT_ROOT / ".ui-forge"

if not UI_FORGE.is_dir():
    print(f"[ui-forge] error: {UI_FORGE} does not exist. Run init-registry.sh first.", flush=True)
    sys.exit(1)

PID_FILE = UI_FORGE / ".server.pid"
sse_clients = []
sse_lock = threading.Lock()
mtime_cache = {}

SCREEN_ID_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")


def write_pid():
    PID_FILE.write_text(str(os.getpid()))


def remove_pid():
    PID_FILE.unlink(missing_ok=True)


def broadcast_reload():
    with sse_lock:
        dead = []
        for wfile in sse_clients:
            try:
                wfile.write(b"event: reload\ndata: {}\n\n")
                wfile.flush()
            except Exception:
                dead.append(wfile)
        for d in dead:
            sse_clients.remove(d)


def watcher():
    while True:
        try:
            for html in UI_FORGE.glob("screens/*/02-forge.html"):
                key = str(html)
                mt = html.stat().st_mtime
                if key in mtime_cache and mtime_cache[key] != mt:
                    broadcast_reload()
                mtime_cache[key] = mt
        except Exception:
            pass
        time.sleep(0.5)


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(UI_FORGE), **kwargs)

    def log_message(self, fmt, *args):
        pass

    def do_POST(self):
        if self.path == "/forge/feedback":
            self._handle_feedback()
        else:
            self.send_error(404)

    def do_GET(self):
        if self.path == "/forge/reload":
            self._handle_sse()
        else:
            super().do_GET()

    def _handle_feedback(self):
        try:
            length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(length)
            payload = json.loads(body)
        except Exception as e:
            self.send_error(400, f"Bad JSON: {e}")
            return

        screen = payload.get("screen", "")
        if not screen or not SCREEN_ID_RE.match(screen):
            self.send_error(400, f"Invalid screen id: {screen!r}")
            return

        round_num = payload.get("round", 1)
        pin_count = payload.get("pinCount", 0)
        new_ids = set(payload.get("newPinIds", []) or [])
        all_pins = payload.get("pins", []) or []
        new_pins = [p for p in all_pins if p.get("id") in new_ids]
        if not new_pins:
            # Re-send with no newPinIds — fall back to every pin so Claude still
            # sees them all.
            new_pins = all_pins

        feedback_dir = UI_FORGE / "screens" / screen / "feedback"
        feedback_dir.mkdir(parents=True, exist_ok=True)

        filename = f"round-{int(round_num):02d}.json"
        file_path = feedback_dir / filename
        file_path.write_text(json.dumps(payload, indent=2))
        (feedback_dir / "latest.json").write_text(json.dumps({
            "file": filename,
            "screen": screen,
            "round": round_num,
            "pinCount": pin_count,
            "receivedAt": time.strftime("%Y-%m-%dT%H:%M:%S"),
        }, indent=2))

        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps({"ok": True, "file": filename}).encode())

        # Monitor surfaces each stdout line as its own event, so we collapse
        # the whole feedback into ONE line. Key info (id, type, location,
        # short comment) is inline; Claude runs scripts/show-pin.py when it
        # needs selector / snapshot / untruncated html — that script is
        # pre-approvable so fetching extra detail is still friction-free.
        print(self._format_feedback_line(screen, round_num, pin_count, new_pins), flush=True)

    @staticmethod
    def _one_line(value, limit):
        s = (value or "")
        s = " ".join(s.split())
        if len(s) > limit:
            s = s[:limit] + "\u2026"
        return s

    @classmethod
    def _format_feedback_line(cls, screen, round_num, pin_count, new_pins):
        segments = []
        for p in new_pins:
            pid = p.get("id")
            ptype = p.get("type", "change")
            region = p.get("region")
            if region:
                loc = f"{region.get('w')}x{region.get('h')}@({region.get('x')},{region.get('y')})"
            else:
                loc = f"@({p.get('x')},{p.get('y')})"
            comment = cls._one_line(p.get("comment") or "", 140).replace("|", "/")
            segments.append(f"#{pid}[{ptype}] {loc} \"{comment}\"")
        pins_part = " || ".join(segments) if segments else "(no new pins)"
        return (
            f"[ui-forge] round={round_num} screen={screen} "
            f"new={len(new_pins)} total={pin_count} | {pins_part} "
            f"| details: show-pin.py {screen} --round {round_num}"
        )

    def _handle_sse(self):
        self.send_response(200)
        self.send_header("Content-Type", "text/event-stream")
        self.send_header("Cache-Control", "no-cache")
        self.send_header("Connection", "keep-alive")
        self.end_headers()

        with sse_lock:
            sse_clients.append(self.wfile)

        try:
            while True:
                self.wfile.write(b": keepalive\n\n")
                self.wfile.flush()
                time.sleep(15)
        except Exception:
            pass
        finally:
            with sse_lock:
                if self.wfile in sse_clients:
                    sse_clients.remove(self.wfile)


def main():
    write_pid()

    def cleanup(*_):
        remove_pid()
        sys.exit(0)

    signal.signal(signal.SIGTERM, cleanup)
    signal.signal(signal.SIGINT, cleanup)

    threading.Thread(target=watcher, daemon=True).start()

    server = http.server.ThreadingHTTPServer(("127.0.0.1", PORT), Handler)
    url = f"http://127.0.0.1:{PORT}"

    screens = list(UI_FORGE.glob("screens/*/02-forge.html"))
    if screens:
        first = screens[0].relative_to(UI_FORGE)
        more = f" (+{len(screens) - 1} more)" if len(screens) > 1 else ""
        print(f"[ui-forge] serving {url} | forge: {url}/{first}{more}", flush=True)
    else:
        print(f"[ui-forge] serving {url} | no forge screens yet", flush=True)

    try:
        server.serve_forever()
    finally:
        remove_pid()


if __name__ == "__main__":
    main()
