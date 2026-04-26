"""Feedback intercept — POST /forge/feedback writes JSON files locally and never proxies."""

from __future__ import annotations

import asyncio
import json
import os
import re
import signal
import subprocess
import sys
import time
from pathlib import Path

import pytest

PLUGIN_ROOT = Path(__file__).resolve().parents[2]
LIVE_PY = PLUGIN_ROOT / "skills" / "ui-forge" / "scripts" / "live" / "live.py"


def _payload(round_num: int = 1, *, session_id: str = "test-session") -> dict:
    return {
        "mode": "live",
        "sessionId": session_id,
        "host": "localhost:3000",
        "path": "/dashboard",
        "round": round_num,
        "exportedAt": "2026-04-27T15:02:11.000Z",
        "pinCount": 1,
        "newPinCount": 1,
        "newPinIds": [round_num],
        "pins": [
            {
                "id": round_num,
                "type": "change",
                "x": 120,
                "y": 340,
                "selector": "div#header",
                "comment": f"comment for round {round_num}",
                "sentInRound": None,
            }
        ],
    }


# ---------------------------------------------------------------------------
# Happy path: writes round-NN.json
# ---------------------------------------------------------------------------

async def test_post_feedback_writes_round_file(live_proxy, tmp_uiforge):
    client, _base, _recorder = live_proxy

    resp = await client.post("/forge/feedback", json=_payload(round_num=1))
    assert resp.status == 200
    body = await resp.json()
    assert body["ok"] is True
    assert body["file"] == "round-01.json"

    round_file = tmp_uiforge / "live" / "test-session" / "round-01.json"
    assert round_file.exists()
    saved = json.loads(round_file.read_text())
    assert saved["round"] == 1
    assert saved["pins"][0]["comment"] == "comment for round 1"


async def test_latest_json_reflects_most_recent_round(live_proxy, tmp_uiforge):
    client, _base, _recorder = live_proxy

    await client.post("/forge/feedback", json=_payload(round_num=1))
    await client.post("/forge/feedback", json=_payload(round_num=2))

    latest = tmp_uiforge / "live" / "test-session" / "latest.json"
    assert latest.exists()
    info = json.loads(latest.read_text())
    assert info["round"] == 2
    assert info["file"] == "round-02.json"
    assert info["sessionId"] == "test-session"
    assert info["host"] == "localhost:3000"
    assert info["path"] == "/dashboard"
    assert info["pinCount"] == 1


# ---------------------------------------------------------------------------
# Stdout trigger format (Monitor regex)
# ---------------------------------------------------------------------------

TRIGGER_RE = re.compile(
    r"^\[ui-forge\] live round=\d+ session=\S+ host=\S+ path=\S+ "
    r"new=\d+ total=\d+ \|.*\| details: show-pin-live\.py \S+ --round \d+$"
)


def test_post_feedback_emits_monitor_line(stub_upstream, tmp_uiforge):
    """Run live.py as a subprocess, send a POST, capture the stdout trigger line.

    We can't capture print() output of an in-process aiohttp app reliably with
    pytest's capsys when the request is fired from within an async test. So
    we spawn live.py in a subprocess and communicate via stdout.
    """
    base_url, _recorder = stub_upstream

    proc = subprocess.Popen(
        [
            sys.executable, str(LIVE_PY),
            "--target", base_url,
            "--port", "0",
            "--name", "stdout-test",
        ],
        cwd=tmp_uiforge.parent,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        bufsize=1,
    )

    try:
        # Wait for the startup line, capture the actual port.
        port = None
        deadline = time.time() + 5.0
        startup_line = None
        while time.time() < deadline:
            line = proc.stdout.readline()
            if not line:
                time.sleep(0.05)
                continue
            startup_line = line.strip()
            m = re.search(r"http://127\.0\.0\.1:(\d+)", startup_line)
            if m:
                port = int(m.group(1))
                break
        assert port is not None, f"never saw startup line; last={startup_line!r}"

        # Send a feedback POST via urllib (no asyncio inside this test).
        import urllib.request
        req = urllib.request.Request(
            f"http://127.0.0.1:{port}/forge/feedback",
            data=json.dumps(_payload(round_num=3, session_id="stdout-test")).encode(),
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        with urllib.request.urlopen(req, timeout=3) as r:
            assert r.status == 200

        # Read the next stdout line — should be the trigger.
        deadline = time.time() + 3.0
        trigger_line = None
        while time.time() < deadline:
            line = proc.stdout.readline()
            if not line:
                time.sleep(0.05)
                continue
            trigger_line = line.strip()
            break
        assert trigger_line is not None, "no trigger line"
        assert TRIGGER_RE.match(trigger_line), (
            f"trigger line does not match expected format: {trigger_line!r}"
        )
        assert "stdout-test" in trigger_line
        assert "round=3" in trigger_line
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=3)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait(timeout=2)


# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------

async def test_post_feedback_400_on_invalid_json(live_proxy):
    client, _base, _recorder = live_proxy
    resp = await client.post(
        "/forge/feedback",
        data="not json",
        headers={"Content-Type": "application/json"},
    )
    assert resp.status == 400


async def test_post_feedback_400_on_missing_session_id(live_proxy):
    client, _base, _recorder = live_proxy
    bad = _payload()
    bad.pop("sessionId")
    resp = await client.post("/forge/feedback", json=bad)
    assert resp.status == 400


async def test_post_feedback_400_on_invalid_session_id_chars(live_proxy):
    client, _base, _recorder = live_proxy
    bad = _payload()
    bad["sessionId"] = "../escape"
    resp = await client.post("/forge/feedback", json=bad)
    assert resp.status == 400


# ---------------------------------------------------------------------------
# Never reaches upstream
# ---------------------------------------------------------------------------

async def test_post_feedback_does_not_reach_upstream(live_proxy):
    client, _base, recorder = live_proxy
    await client.post("/forge/feedback", json=_payload())
    assert all(path != "/forge/feedback" for _m, path in recorder.requests), (
        f"feedback was forwarded upstream: {recorder.requests}"
    )
