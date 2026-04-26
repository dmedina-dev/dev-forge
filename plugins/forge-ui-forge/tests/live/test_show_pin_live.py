"""show-pin-live.py — dump pin details from a live-mode round."""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

PLUGIN_ROOT = Path(__file__).resolve().parents[2]
SHOW_PIN_LIVE = PLUGIN_ROOT / "skills" / "ui-forge" / "scripts" / "live" / "show-pin-live.py"


def _seed_round(uiforge: Path, session: str, round_num: int, pins: list, *, write_latest: bool = True) -> None:
    sess_dir = uiforge / "live" / session
    sess_dir.mkdir(parents=True, exist_ok=True)
    payload = {
        "mode": "live",
        "sessionId": session,
        "host": "localhost:3000",
        "path": "/dashboard",
        "round": round_num,
        "exportedAt": "2026-04-27T15:02:11.000Z",
        "pinCount": len(pins),
        "newPinCount": len(pins),
        "newPinIds": [p["id"] for p in pins],
        "pins": pins,
    }
    filename = f"round-{round_num:02d}.json"
    (sess_dir / filename).write_text(json.dumps(payload, indent=2))
    if write_latest:
        (sess_dir / "latest.json").write_text(json.dumps({
            "file": filename,
            "sessionId": session,
            "host": "localhost:3000",
            "path": "/dashboard",
            "round": round_num,
            "pinCount": len(pins),
            "receivedAt": "2026-04-27T15:02:12",
        }, indent=2))


def _run(args: list, *, cwd: Path) -> subprocess.CompletedProcess:
    return subprocess.run(
        [sys.executable, str(SHOW_PIN_LIVE), *args],
        cwd=cwd, capture_output=True, text=True, timeout=10,
    )


def test_show_pin_live_prints_pin_details(tmp_uiforge):
    pins = [
        {"id": 1, "type": "change", "x": 12, "y": 34, "selector": "div#a", "comment": "first"},
        {"id": 2, "type": "extract-as-component", "x": 50, "y": 60, "selector": "div#b", "comment": "second"},
    ]
    _seed_round(tmp_uiforge, "s1", 3, pins)

    result = _run(["s1", "--round", "3", "--pin", "2"], cwd=tmp_uiforge.parent)
    assert result.returncode == 0
    assert "second" in result.stdout
    assert "div#b" in result.stdout
    assert "Pin #2" in result.stdout
    # The other pin should NOT show up when --pin filters
    assert "first" not in result.stdout


def test_show_pin_live_ids_lists_only_ids(tmp_uiforge):
    pins = [
        {"id": 1, "type": "change", "x": 0, "y": 0, "selector": "x"},
        {"id": 7, "type": "data-issue", "x": 0, "y": 0, "selector": "y"},
    ]
    _seed_round(tmp_uiforge, "s1", 1, pins)

    result = _run(["s1", "--ids"], cwd=tmp_uiforge.parent)
    assert result.returncode == 0
    lines = [l for l in result.stdout.splitlines() if l.strip()]
    assert "1\tchange" in lines
    assert "7\tdata-issue" in lines


def test_show_pin_live_default_round_via_latest(tmp_uiforge):
    _seed_round(tmp_uiforge, "s1", 1, [{"id": 1, "type": "change", "x": 0, "y": 0, "comment": "PREVIOUS_ROUND_MARKER"}])
    _seed_round(tmp_uiforge, "s1", 2, [{"id": 2, "type": "change", "x": 0, "y": 0, "comment": "LATEST_ROUND_MARKER"}])

    result = _run(["s1"], cwd=tmp_uiforge.parent)
    assert result.returncode == 0
    assert "LATEST_ROUND_MARKER" in result.stdout
    assert "PREVIOUS_ROUND_MARKER" not in result.stdout


def test_show_pin_live_list_sessions(tmp_uiforge):
    _seed_round(tmp_uiforge, "session-a", 1, [{"id": 1, "type": "change", "x": 0, "y": 0}])
    _seed_round(tmp_uiforge, "session-b", 2, [{"id": 2, "type": "change", "x": 0, "y": 0}])

    result = _run(["--list-sessions"], cwd=tmp_uiforge.parent)
    assert result.returncode == 0
    assert "session-a" in result.stdout
    assert "session-b" in result.stdout
    assert "round=" in result.stdout


def test_show_pin_live_unknown_session_errors(tmp_uiforge):
    result = _run(["nonexistent"], cwd=tmp_uiforge.parent)
    assert result.returncode != 0
    assert "no session" in result.stderr or "no session" in result.stdout


def test_show_pin_live_json_output(tmp_uiforge):
    pins = [{"id": 1, "type": "change", "x": 0, "y": 0, "comment": "json-test"}]
    _seed_round(tmp_uiforge, "s1", 1, pins)

    result = _run(["s1", "--json"], cwd=tmp_uiforge.parent)
    assert result.returncode == 0
    parsed = json.loads(result.stdout)
    assert parsed["round"] == 1
    assert parsed["pins"][0]["comment"] == "json-test"
