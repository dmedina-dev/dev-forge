"""Lifecycle scripts (stop-live, status-live) and clean SIGTERM shutdown."""

from __future__ import annotations

import asyncio
import os
import re
import signal
import subprocess
import sys
import time
from pathlib import Path

import aiohttp
import pytest

PLUGIN_ROOT = Path(__file__).resolve().parents[2]
LIVE_PY = PLUGIN_ROOT / "skills" / "ui-forge" / "scripts" / "live" / "live.py"
STOP_LIVE_SH = PLUGIN_ROOT / "skills" / "ui-forge" / "scripts" / "live" / "stop-live.sh"
STATUS_LIVE_SH = PLUGIN_ROOT / "skills" / "ui-forge" / "scripts" / "live" / "status-live.sh"


def _spawn_proxy(target_url: str, cwd: Path):
    proc = subprocess.Popen(
        [
            sys.executable, str(LIVE_PY),
            "--target", target_url,
            "--port", "0",
            "--name", "shutdown-test",
        ],
        cwd=cwd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        bufsize=1,
    )
    deadline = time.time() + 5
    port = None
    while time.time() < deadline:
        line = proc.stdout.readline()
        if not line:
            time.sleep(0.05)
            continue
        m = re.search(r"http://127\.0\.0\.1:(\d+)", line)
        if m:
            port = int(m.group(1))
            break
    assert port is not None, "proxy never printed startup line"
    return proc, port


# ---------------------------------------------------------------------------
# stop-live.sh
# ---------------------------------------------------------------------------

def test_stop_live_with_no_pid_file_says_no_proxy(tmp_uiforge):
    result = subprocess.run(
        ["bash", str(STOP_LIVE_SH)],
        cwd=tmp_uiforge.parent,
        capture_output=True, text=True, timeout=5,
    )
    assert result.returncode == 0
    assert "no proxy running" in result.stdout


def test_stop_live_kills_running_proxy(stub_upstream, tmp_uiforge):
    base_url, _recorder = stub_upstream
    proc, _port = _spawn_proxy(base_url, tmp_uiforge.parent)
    try:
        pid_file = tmp_uiforge / ".live-server.pid"
        deadline = time.time() + 5
        while time.time() < deadline and not pid_file.exists():
            time.sleep(0.05)
        assert pid_file.exists()

        result = subprocess.run(
            ["bash", str(STOP_LIVE_SH)],
            cwd=tmp_uiforge.parent,
            capture_output=True, text=True, timeout=5,
        )
        assert result.returncode == 0
        assert "stopped proxy" in result.stdout

        # Wait for the proxy process to actually exit.
        try:
            proc.wait(timeout=3)
        except subprocess.TimeoutExpired:
            pytest.fail("proxy did not exit after stop-live.sh")
        assert not pid_file.exists()
    finally:
        if proc.poll() is None:
            proc.terminate()
            try:
                proc.wait(timeout=2)
            except subprocess.TimeoutExpired:
                proc.kill()


# ---------------------------------------------------------------------------
# status-live.sh
# ---------------------------------------------------------------------------

def test_status_live_reports_not_running_when_no_pid(tmp_uiforge):
    result = subprocess.run(
        ["bash", str(STATUS_LIVE_SH)],
        cwd=tmp_uiforge.parent,
        capture_output=True, text=True, timeout=5,
    )
    assert result.returncode == 0
    assert "not running" in result.stdout


def test_status_live_reports_running_with_pid_and_port(stub_upstream, tmp_uiforge):
    base_url, _recorder = stub_upstream
    proc, _port = _spawn_proxy(base_url, tmp_uiforge.parent)
    try:
        deadline = time.time() + 5
        pid_file = tmp_uiforge / ".live-server.pid"
        while time.time() < deadline and not pid_file.exists():
            time.sleep(0.05)
        assert pid_file.exists()

        result = subprocess.run(
            ["bash", str(STATUS_LIVE_SH)],
            cwd=tmp_uiforge.parent,
            capture_output=True, text=True, timeout=5,
        )
        assert result.returncode == 0
        assert "running" in result.stdout
        assert "4270" in result.stdout  # status-live always prints the default port
        pid_in_output = re.search(r"PID (\d+)", result.stdout)
        assert pid_in_output, f"no PID in: {result.stdout!r}"
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=3)
        except subprocess.TimeoutExpired:
            proc.kill()


# ---------------------------------------------------------------------------
# Clean shutdown — SIGTERM closes WS within 2s
# ---------------------------------------------------------------------------

async def test_sigterm_closes_proxy_cleanly(stub_upstream, tmp_uiforge):
    """Spawn proxy, open a WS through it, send SIGTERM, expect clean exit + no PID."""
    base_url, _recorder = stub_upstream
    proc, port = _spawn_proxy(base_url, tmp_uiforge.parent)

    try:
        async with aiohttp.ClientSession() as session:
            ws = await session.ws_connect(f"http://127.0.0.1:{port}/ws")
            await ws.send_str("hello")
            await asyncio.wait_for(ws.receive(), timeout=2.0)

            # WS is open. SIGTERM.
            proc.send_signal(signal.SIGTERM)

            # proc.wait blocks the asyncio loop, so use a thread-friendly variant.
            try:
                rc = await asyncio.wait_for(
                    asyncio.to_thread(proc.wait, 3), timeout=4
                )
            except (subprocess.TimeoutExpired, asyncio.TimeoutError):
                proc.kill()
                pytest.fail("SIGTERM did not stop the proxy within 3s")

            assert rc == 0, f"expected exit code 0, got {rc}"
            pid_file = tmp_uiforge / ".live-server.pid"
            assert not pid_file.exists(), "PID file should be removed on clean shutdown"

            await ws.close()
    finally:
        if proc.poll() is None:
            proc.kill()
            proc.wait(timeout=2)
