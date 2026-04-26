"""Test that live.sh aborts cleanly with a helpful message when aiohttp is missing."""

from __future__ import annotations

import shutil
import subprocess
import sys
from pathlib import Path
import os

PLUGIN_ROOT = Path(__file__).resolve().parents[2]
LIVE_SH = PLUGIN_ROOT / "skills" / "ui-forge" / "scripts" / "live" / "live.sh"


def _make_aiohttp_free_python(tmp_path: Path) -> str:
    """Create a tiny python wrapper that fails to import aiohttp.

    We achieve this by setting PYTHONPATH to a directory containing a fake
    `aiohttp/__init__.py` that raises on import. Real aiohttp is shadowed.
    """
    fake_aiohttp = tmp_path / "fake-pythonpath" / "aiohttp"
    fake_aiohttp.mkdir(parents=True)
    (fake_aiohttp / "__init__.py").write_text(
        "raise ImportError('simulated: aiohttp unavailable for preflight test')\n"
    )
    return str(tmp_path / "fake-pythonpath")


def test_live_sh_exists():
    """Sanity: the script must exist before we can preflight it."""
    assert LIVE_SH.exists(), f"{LIVE_SH} does not exist yet"


def test_preflight_aborts_without_aiohttp(tmp_path):
    """live.sh must exit non-zero with `pip install aiohttp` hint when aiohttp can't import."""
    fake_path = _make_aiohttp_free_python(tmp_path)

    env = os.environ.copy()
    # Prepend so the fake aiohttp shadows the real one inside the subprocess.
    env["PYTHONPATH"] = fake_path + os.pathsep + env.get("PYTHONPATH", "")

    # We need a real .ui-forge/ for live.py to even consider running, but
    # preflight should fail BEFORE that check.
    (tmp_path / ".ui-forge").mkdir(exist_ok=True)

    result = subprocess.run(
        ["bash", str(LIVE_SH), "--target", "http://127.0.0.1:9999"],
        cwd=tmp_path,
        env=env,
        capture_output=True,
        text=True,
        timeout=10,
    )

    assert result.returncode != 0, (
        f"Expected non-zero exit, got {result.returncode}.\n"
        f"stdout={result.stdout!r}\nstderr={result.stderr!r}"
    )
    combined = result.stdout + result.stderr
    assert "pip install aiohttp" in combined, (
        f"Expected 'pip install aiohttp' in output. Got:\n{combined}"
    )
