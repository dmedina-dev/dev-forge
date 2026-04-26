"""overlay.js live branch — gated by window.UIFORGE_MODE === 'live'.

Tests are source-level: assert that overlay.js contains the live-mode
constants and conditionals. The IIFE-wrapped overlay is hard to exercise
in isolation without a real browser, so we verify the structural invariants
that make the live branch correct (storage key, payload fields, SSE skip,
scenario UI gated). End-to-end behavior is covered by manual smoke testing
during Wave 8.
"""

from __future__ import annotations

import re
from pathlib import Path

PLUGIN_ROOT = Path(__file__).resolve().parents[2]
OVERLAY_JS = PLUGIN_ROOT / "skills" / "ui-forge" / "assets" / "overlay.js"


def _read() -> str:
    return OVERLAY_JS.read_text()


def test_overlay_defines_is_live_constant():
    src = _read()
    assert re.search(r"\bIS_LIVE\s*=\s*window\.UIFORGE_MODE\s*===\s*['\"]live['\"]", src), (
        "missing IS_LIVE = window.UIFORGE_MODE === 'live' constant"
    )


def test_storage_key_branches_on_is_live():
    """STORAGE_KEY in live mode must use uiforge:live:<host>: prefix."""
    src = _read()
    # Either via a KEY_BASE intermediate or inline ternary — both forms accepted.
    assert "uiforge:live:" in src, "STORAGE_KEY does not include 'uiforge:live:' prefix"
    assert re.search(r"IS_LIVE\s*\?[^:]+uiforge:live:", src), (
        "STORAGE_KEY should branch on IS_LIVE"
    )


def test_buildPayload_has_live_branch():
    """buildPayload must include mode/sessionId/host/path when IS_LIVE."""
    src = _read()
    # Find the buildPayload function and read until the next function or end of section.
    m = re.search(r"function buildPayload\([^)]*\)\s*\{(.+?)(?=\n\s*function |\n\s*\}\)\(\);)", src, re.DOTALL)
    assert m, "buildPayload function not found"
    body = m.group(1)
    assert "IS_LIVE" in body, "buildPayload should branch on IS_LIVE"
    assert "'live'" in body, "live-mode payload missing literal 'live'"
    assert "sessionId" in body, "live-mode payload missing sessionId"
    assert "host" in body, "live-mode payload missing host"
    assert "path" in body, "live-mode payload missing path"


def test_setupSSE_is_skipped_in_live_mode():
    """setupSSE early-returns when IS_LIVE so the proxy doesn't get /forge/reload requests."""
    src = _read()
    m = re.search(r"function setupSSE\([^)]*\)\s*\{\s*\n([^\n]+)", src)
    assert m, "setupSSE function not found"
    first_line = m.group(1)
    assert "IS_LIVE" in first_line, (
        f"setupSSE should early-return on IS_LIVE; first line was: {first_line!r}"
    )


def test_scenario_ui_is_gated_on_is_live():
    """The scenario <select> in renderPanel should be hidden in live mode."""
    src = _read()
    # The scenario select line should be inside a conditional that excludes IS_LIVE.
    # Simplest invariant: somewhere near `uiforge-scenario` there's a `!IS_LIVE` guard
    # or the select is built only when not IS_LIVE.
    assert re.search(r"!\s*IS_LIVE.*uiforge-scenario|uiforge-scenario.*!\s*IS_LIVE", src, re.DOTALL), (
        "scenario UI should be guarded by !IS_LIVE in renderPanel"
    )


def test_existing_prototype_constants_still_present():
    """Regression — prototype-mode references must not be removed."""
    src = _read()
    assert "UIFORGE_SCREEN_ID" in src
    assert "UIFORGE_DATA" in src
    assert "UIFORGE_SCENARIOS" in src
    assert "/forge/feedback" in src
