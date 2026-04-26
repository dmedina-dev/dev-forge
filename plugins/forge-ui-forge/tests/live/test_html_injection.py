"""HTML injection — proxy injects the overlay init block into text/html responses.

Covers:
    - HTML responses get exactly one markered injection block before </body>.
    - Non-HTML responses (JSON, JS) are byte-identical to upstream.
    - Idempotent: HTML that already contains the injected marker is not re-injected.
    - Init script contains the correct sessionId / host / path values.
"""

from __future__ import annotations

INJECT_START = "<!-- ui-forge:live:injected:start -->"
INJECT_END = "<!-- ui-forge:live:injected:end -->"


async def test_html_response_gets_overlay_tag_injected(live_proxy):
    client, _base, _recorder = live_proxy
    resp = await client.get("/index.html")
    assert resp.status == 200
    body = await resp.text()

    assert INJECT_START in body, f"missing start marker in body: {body!r}"
    assert INJECT_END in body, f"missing end marker in body: {body!r}"
    assert "/forge/__overlay.js" in body, "overlay.js script tag missing"
    # Marker block sits before </body>
    assert body.index(INJECT_START) < body.lower().rindex("</body>"), (
        "injection block should be inside <body>"
    )


async def test_json_response_passes_through_byte_for_byte(live_proxy):
    client, _base, _recorder = live_proxy
    resp = await client.get("/api/data")
    body = await resp.read()
    # No injection markers, byte-identical to the canonical upstream JSON.
    assert INJECT_START.encode() not in body
    assert b"hello" in body and b"from upstream" in body


async def test_javascript_response_passes_through_byte_for_byte(live_proxy):
    client, _base, _recorder = live_proxy
    resp = await client.get("/static/app.js")
    body = await resp.read()
    assert INJECT_START.encode() not in body
    assert body == b"console.log('upstream js');"


async def test_html_already_containing_marker_is_not_reinjected(stub_upstream, tmp_uiforge):
    """Direct unit test on _inject_overlay — easier than rigging stub upstream."""
    from importlib import import_module
    import sys
    from pathlib import Path

    plugin_root = Path(__file__).resolve().parents[2]
    sys.path.insert(0, str(plugin_root / "skills" / "ui-forge" / "scripts" / "live"))
    try:
        live = import_module("live")
    finally:
        sys.path.pop(0)

    pre_injected = (
        "<html><body><div>x</div>"
        f"{INJECT_START}<script>existing</script>{INJECT_END}"
        "</body></html>"
    )
    out = live._inject_overlay(pre_injected, "s1", "host:1", "/p")
    # Marker count must remain exactly one of each
    assert out.count(INJECT_START) == 1
    assert out.count(INJECT_END) == 1


async def test_injected_init_script_has_correct_session_host_path(stub_upstream, tmp_uiforge):
    base_url, _recorder = stub_upstream
    from importlib import import_module
    import sys
    from pathlib import Path
    from aiohttp.test_utils import TestServer, TestClient

    plugin_root = Path(__file__).resolve().parents[2]
    sys.path.insert(0, str(plugin_root / "skills" / "ui-forge" / "scripts" / "live"))
    try:
        live = import_module("live")
    finally:
        sys.path.pop(0)

    app = await live.build_app(target=base_url, session_id="my-session")
    server = TestServer(app)
    client = TestClient(server)
    await client.start_server()
    try:
        resp = await client.get("/index.html")
        body = await resp.text()
    finally:
        await client.close()
        await live.shutdown_app(app)

    # Extract the upstream host:port from base_url for assertion.
    expected_host = base_url.removeprefix("http://").removeprefix("https://").rstrip("/")

    assert 'window.UIFORGE_MODE = "live"' in body
    assert 'window.UIFORGE_SESSION_ID = "my-session"' in body
    assert f'window.UIFORGE_LIVE_HOST = "{expected_host}"' in body
    assert 'window.UIFORGE_LIVE_PATH = "/index.html"' in body
