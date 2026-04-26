"""HTTP passthrough — proxy forwards GET/POST/PUT to the upstream verbatim.

Tests in this file exercise:
    - PID file is written when the proxy starts.
    - GET requests pass through with body, status, content-type preserved.
    - POST requests forward the body and return the upstream response.
    - PUT requests work too (sanity that the catch-all method is generic).
"""

from __future__ import annotations

import os
import signal
import subprocess
import sys
import time
from pathlib import Path

import pytest

PLUGIN_ROOT = Path(__file__).resolve().parents[2]
LIVE_PY = PLUGIN_ROOT / "skills" / "ui-forge" / "scripts" / "live" / "live.py"


# ---------------------------------------------------------------------------
# PID file is written when the proxy starts
# ---------------------------------------------------------------------------

def test_proxy_starts_and_writes_pid(stub_upstream, tmp_uiforge):
    """Spawn live.py as a subprocess; assert PID file appears within 5s."""
    base_url, _recorder = stub_upstream

    proc = subprocess.Popen(
        [
            sys.executable,
            str(LIVE_PY),
            "--target", base_url,
            "--port", "0",  # let the OS pick to avoid port conflicts in CI
            "--name", "test-pid",
        ],
        cwd=tmp_uiforge.parent,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )

    pid_file = tmp_uiforge / ".live-server.pid"
    deadline = time.time() + 5.0
    try:
        while time.time() < deadline:
            if pid_file.exists() and pid_file.read_text().strip():
                break
            time.sleep(0.05)
        else:
            stdout, stderr = proc.communicate(timeout=1)
            pytest.fail(
                f"PID file {pid_file} did not appear within 5s.\n"
                f"stdout={stdout!r}\nstderr={stderr!r}"
            )

        recorded_pid = int(pid_file.read_text().strip())
        # On macOS we typically see proc.pid OR a child PID very close to it.
        # The PID file should match the process that's actually serving.
        assert recorded_pid > 0
        # Process must be alive
        os.kill(recorded_pid, 0)
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=3)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait(timeout=2)


# ---------------------------------------------------------------------------
# HTTP passthrough — GET
# ---------------------------------------------------------------------------

async def test_get_passes_through_to_upstream(live_proxy):
    client, _base_url, recorder = live_proxy
    resp = await client.get("/api/data")
    assert resp.status == 200
    assert resp.headers["Content-Type"].startswith("application/json")
    body = await resp.json()
    assert body == {"hello": "from upstream", "n": 42}
    assert ("GET", "/api/data") in recorder.requests


# ---------------------------------------------------------------------------
# HTTP passthrough — POST + PUT
# ---------------------------------------------------------------------------

async def test_post_forwards_body_and_returns_response(live_proxy):
    client, _base_url, recorder = live_proxy
    payload = {"a": 1, "b": "two"}
    resp = await client.post("/api/echo", json=payload)
    assert resp.status == 200
    body = await resp.json()
    assert body == {"echo": payload}
    assert ("POST", "/api/echo") in recorder.requests


async def test_put_method_passes_through(live_proxy):
    client, _base_url, recorder = live_proxy
    resp = await client.put("/some/resource", data=b"raw-body")
    # Upstream stub doesn't define PUT so it falls through to the catch-all
    # 404 handler — but the recorder still logs the request.
    assert resp.status == 404
    assert ("PUT", "/some/resource") in recorder.requests
