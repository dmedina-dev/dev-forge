"""Static endpoints — proxy serves /forge/__overlay.js from .ui-forge/assets/."""

from __future__ import annotations


async def test_overlay_js_endpoint_returns_file(live_proxy, tmp_uiforge):
    client, _base, _recorder = live_proxy
    overlay = tmp_uiforge / "assets" / "overlay.js"
    overlay.write_text("// fake overlay for tests\n")

    resp = await client.get("/forge/__overlay.js")
    assert resp.status == 200
    assert resp.headers["Content-Type"].startswith("application/javascript")
    body = await resp.text()
    assert body == "// fake overlay for tests\n"


async def test_overlay_js_missing_returns_503_with_hint(live_proxy, tmp_uiforge):
    client, _base, _recorder = live_proxy
    # Intentionally do not create assets/overlay.js
    resp = await client.get("/forge/__overlay.js")
    assert resp.status == 503
    body = await resp.text()
    assert "init-registry.sh" in body
    assert "overlay.js" in body


async def test_overlay_js_does_not_reach_upstream(live_proxy, tmp_uiforge):
    """The /forge/__overlay.js route must be served locally, never proxied."""
    client, _base, recorder = live_proxy
    (tmp_uiforge / "assets" / "overlay.js").write_text("// x")
    await client.get("/forge/__overlay.js")
    proxied = [r for r in recorder.requests if r[1] == "/forge/__overlay.js"]
    assert proxied == [], f"upstream was contacted: {proxied}"
