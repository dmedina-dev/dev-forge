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

        feedback_dir = UI_FORGE / "screens" / screen / "feedback"
        feedback_dir.mkdir(parents=True, exist_ok=True)

        filename = f"round-{int(round_num):02d}.json"
        (feedback_dir / filename).write_text(json.dumps(payload, indent=2))
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

        print(
            f"[ui-forge] feedback screen={screen} round={round_num} pins={pin_count}",
            flush=True,
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
    print(f"[ui-forge] serving {UI_FORGE} on {url}", flush=True)
    if screens:
        for s in screens:
            rel = s.relative_to(UI_FORGE)
            print(f"[ui-forge] forge: {url}/{rel}", flush=True)
    else:
        print("[ui-forge] no forge screens yet — start prototyping to create one", flush=True)

    try:
        server.serve_forever()
    finally:
        remove_pid()


if __name__ == "__main__":
    main()
