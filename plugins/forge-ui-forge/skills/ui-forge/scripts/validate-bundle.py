#!/usr/bin/env python3
"""
validate-bundle — mechanical checker for the ui-forge Phase 5 handoff bundle.

Verifies the falsifiable invariants declared in
references/output-data-model.md:

  #1  every entity referenced by screen.html's inlined data is declared in
      data/schema.json
  #3  every component in output/components-used.json is present in
      registry/manifest.json at the pinned version
  #4  every fixture in output/components-used.json exists in
      registry/fixtures/index.json and on disk
  #5  output/screen.html contains no <!-- ui-forge:* --> markers and no
      data-uiforge-* attributes (Phase 4 strip is complete)
  #7  every pinned component version has both component.html and spec.md

Skipped — not mechanically falsifiable:
  #2  tokens — output/screen.html is intentionally a frozen visual snapshot,
      so token-name purity is not enforced on it (see output-data-model.md
      § Single source of truth per fact).
  #6  behavior — judgment call; no reliable text proxy that does not produce
      false positives.

Usage (run from the project root, the directory containing .ui-forge/):
    python3 <plugin-path>/scripts/validate-bundle.py [screen-id]

Without a screen-id, every screen under .ui-forge/screens/ is validated.

Exit codes:
    0   all checked invariants hold
    1   at least one violation
    2   .ui-forge/ not present (run from the wrong directory)
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

# Match the inlined data block regardless of attribute order. The template
# emits <script id="uiforge-data" type="application/json">…</script>; Phase 4
# is expected to keep the same id when it strips down to mock.json.
SCRIPT_DATA_RE = re.compile(
    r'<script\b[^>]*\bid="uiforge-data"[^>]*>(.*?)</script>',
    re.DOTALL,
)

OVERLAY_MARKER_RE = re.compile(r"<!--\s*ui-forge:[^>]*-->")
DATA_UIFORGE_ATTR_RE = re.compile(r'\sdata-uiforge-[a-z0-9-]+\s*=')


Result = tuple[str, str, str]  # (severity, screen, message)


def add(results: list[Result], severity: str, screen: str, message: str) -> None:
    results.append((severity, screen, message))


def load_json(path: Path) -> tuple[dict | list | None, str | None]:
    try:
        return json.loads(path.read_text()), None
    except FileNotFoundError:
        return None, f"missing: {path}"
    except json.JSONDecodeError as e:
        return None, f"invalid JSON in {path}: {e}"


def check_invariant_1(screen_dir: Path, screen: str, results: list[Result]) -> None:
    screen_html = screen_dir / "output" / "screen.html"
    schema_path = screen_dir / "data" / "schema.json"

    if not screen_html.is_file():
        add(results, "FAIL", screen, f"#1 cannot run: {screen_html} missing — Phase 4 not complete")
        return
    if not schema_path.is_file():
        add(results, "FAIL", screen, f"#1 cannot run: {schema_path} missing")
        return

    html = screen_html.read_text()
    m = SCRIPT_DATA_RE.search(html)
    if not m:
        add(results, "FAIL", screen, '#1 no <script id="uiforge-data"> block found in screen.html')
        return

    try:
        data = json.loads(m.group(1))
    except json.JSONDecodeError as e:
        add(results, "FAIL", screen, f"#1 inlined data is invalid JSON: {e}")
        return

    if not isinstance(data, dict):
        add(results, "FAIL", screen, f"#1 inlined data is not a JSON object (got {type(data).__name__})")
        return

    # Phase 4 inlines only mock.json so top-level keys = entity names. But if
    # the distillation produced a single-scenario wrapper (e.g. {"happy": {…}}),
    # unwrap once before comparing.
    top_keys = list(data.keys())
    if len(top_keys) == 1 and isinstance(data[top_keys[0]], dict) and top_keys[0] in {"happy", "default", "mock"}:
        entities_in_html = set(data[top_keys[0]].keys())
    else:
        entities_in_html = set(top_keys)

    schema, err = load_json(schema_path)
    if err:
        add(results, "FAIL", screen, f"#1 {err}")
        return
    if not isinstance(schema, dict):
        add(results, "FAIL", screen, f"#1 schema.json is not a JSON object")
        return

    declared = set((schema.get("entities") or {}).keys())
    orphans = entities_in_html - declared

    if orphans:
        add(results, "FAIL", screen,
            f"#1 entities present in screen.html but not declared in schema.json: {sorted(orphans)}")
    else:
        add(results, "PASS", screen,
            f"#1 entities ({len(entities_in_html)}) all declared in schema.json")


def check_components_and_fixtures(
    screen_dir: Path, ui_forge: Path, screen: str, results: list[Result]
) -> None:
    used_path = screen_dir / "output" / "components-used.json"
    manifest_path = ui_forge / "registry" / "manifest.json"
    fixtures_index_path = ui_forge / "registry" / "fixtures" / "index.json"

    if not used_path.is_file():
        add(results, "FAIL", screen, f"#3/#4/#7 cannot run: {used_path} missing — Phase 4 not complete")
        return

    used, err = load_json(used_path)
    if err:
        add(results, "FAIL", screen, f"#3 {err}")
        return
    if not isinstance(used, dict):
        add(results, "FAIL", screen, f"#3 components-used.json is not a JSON object")
        return

    # --- Invariant #3 + #7
    manifest, err = load_json(manifest_path)
    if err:
        add(results, "FAIL", screen, f"#3 {err}")
        manifest = None

    declared_components: dict[tuple[str, str], dict] = {}
    if isinstance(manifest, dict):
        for c in manifest.get("components") or []:
            cid = c.get("id")
            if not cid:
                continue
            for v in c.get("versions") or []:
                declared_components[(cid, v)] = c

    registry_components = used.get("registryComponents") or []
    missing_in_manifest: list[str] = []
    missing_artifacts: list[str] = []
    artifacts_checked = 0

    for entry in registry_components:
        cid = entry.get("id")
        ver = entry.get("version")
        if not cid or not ver:
            missing_in_manifest.append(f"{entry!r} (incomplete entry)")
            continue
        if manifest is not None and (cid, ver) not in declared_components:
            missing_in_manifest.append(f"{cid}@{ver}")
            continue
        comp_dir = ui_forge / "registry" / "components" / cid / ver
        artifacts_checked += 1
        for artifact in ("component.html", "spec.md"):
            if not (comp_dir / artifact).is_file():
                missing_artifacts.append(f"{cid}@{ver}/{artifact}")

    if missing_in_manifest:
        add(results, "FAIL", screen,
            f"#3 components pinned but not in manifest.json: {missing_in_manifest}")
    elif manifest is not None:
        add(results, "PASS", screen,
            f"#3 all {len(registry_components)} pinned components present in manifest")

    if missing_artifacts:
        add(results, "FAIL", screen,
            f"#7 component versions missing required files: {missing_artifacts}")
    elif artifacts_checked > 0:
        add(results, "PASS", screen,
            f"#7 every pinned version ({artifacts_checked}) has component.html + spec.md")
    # If artifacts_checked == 0 (no components, or all already failed #3),
    # #7 has nothing to verify — stay silent rather than emit a misleading PASS.

    # --- Invariant #4
    fixtures_used = used.get("fixturesUsed") or []
    if not fixtures_used:
        return

    fixtures_index: dict | None = None
    if fixtures_index_path.is_file():
        fi, err = load_json(fixtures_index_path)
        if err:
            add(results, "FAIL", screen, f"#4 {err}")
            return
        if not isinstance(fi, dict):
            add(results, "FAIL", screen, "#4 fixtures/index.json is not a JSON object")
            return
        fixtures_index = fi
    else:
        add(results, "FAIL", screen,
            f"#4 components-used.json pins {len(fixtures_used)} fixture(s) but "
            f"{fixtures_index_path} is missing")
        return

    missing_fixtures: list[str] = []
    for name in fixtures_used:
        if name not in fixtures_index:
            missing_fixtures.append(f"{name} (not in fixtures/index.json)")
            continue
        fixture_file = ui_forge / "registry" / "fixtures" / f"{name}.json"
        if not fixture_file.is_file():
            missing_fixtures.append(f"{name} (file missing: {fixture_file.name})")

    if missing_fixtures:
        add(results, "FAIL", screen, f"#4 fixtures pinned but unresolved: {missing_fixtures}")
    else:
        add(results, "PASS", screen, f"#4 all {len(fixtures_used)} fixtures resolved")


def check_invariant_5(screen_dir: Path, screen: str, results: list[Result]) -> None:
    screen_html = screen_dir / "output" / "screen.html"
    if not screen_html.is_file():
        add(results, "FAIL", screen, f"#5 cannot run: {screen_html} missing")
        return

    text = screen_html.read_text()
    overlay_markers = OVERLAY_MARKER_RE.findall(text)
    data_attrs = DATA_UIFORGE_ATTR_RE.findall(text)

    if overlay_markers or data_attrs:
        parts = []
        if overlay_markers:
            parts.append(f"{len(overlay_markers)} <!-- ui-forge:* --> marker(s)")
        if data_attrs:
            parts.append(f"{len(data_attrs)} data-uiforge-* attribute(s)")
        add(results, "FAIL", screen,
            f"#5 screen.html still contains: {', '.join(parts)} — Phase 4 strip incomplete")
    else:
        add(results, "PASS", screen,
            "#5 screen.html is clean (no overlay markers or data-uiforge-* attributes)")


def discover_screens(ui_forge: Path, requested: str | None, results: list[Result]) -> list[Path]:
    screens_dir = ui_forge / "screens"
    if requested:
        screen_dir = screens_dir / requested
        if not screen_dir.is_dir():
            add(results, "FAIL", requested, f"screen directory not found: {screen_dir}")
            return []
        return [screen_dir]

    if not screens_dir.is_dir():
        return []
    return sorted(p for p in screens_dir.iterdir() if p.is_dir())


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Validate the ui-forge Phase 5 handoff bundle.",
    )
    parser.add_argument(
        "screen_id",
        nargs="?",
        help="Validate a single screen by id; default = every screen under .ui-forge/screens/",
    )
    args = parser.parse_args()

    project_root = Path.cwd()
    ui_forge = project_root / ".ui-forge"
    if not ui_forge.is_dir():
        sys.stderr.write(
            f"[validate-bundle] error: {ui_forge} not found. "
            f"Run from the project root (the directory containing .ui-forge/).\n"
        )
        return 2

    results: list[Result] = []
    screens = discover_screens(ui_forge, args.screen_id, results)

    if not screens and not results:
        print("[validate-bundle] no screens found under .ui-forge/screens/")
        return 0

    for screen_dir in screens:
        screen = screen_dir.name
        check_invariant_1(screen_dir, screen, results)
        check_components_and_fixtures(screen_dir, ui_forge, screen, results)
        check_invariant_5(screen_dir, screen, results)

    fails = sum(1 for r in results if r[0] == "FAIL")
    passes = sum(1 for r in results if r[0] == "PASS")

    for severity, screen, message in results:
        print(f"  {severity}  [{screen}] {message}")

    print(f"[validate-bundle] {passes} passed, {fails} failed", flush=True)
    return 0 if fails == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
