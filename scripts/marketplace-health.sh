#!/usr/bin/env bash
#
# marketplace-health.sh — pre-publish sanity check for marketplace.json + plugins.
#
# Run before every push that touches .claude-plugin/marketplace.json or any
# plugin's .claude-plugin/plugin.json. Catches the failure modes we have hit
# in production:
#
#   - dependencies declared as an object (Claude Code expects flat array of
#     plugin names — anything else makes /plugin marketplace add fail).
#   - source URLs using git@ssh (must be https for public access).
#   - plugin.json version drifting from its marketplace.json entry version.
#   - plugin.json name drifting from its marketplace.json entry name.
#   - marketplace entries pointing at paths that no longer exist (rename
#     left a stale path).
#   - dependencies referencing plugin names that aren't in the catalog
#     (typo or removed plugin).
#   - install-all.md not regenerated after a marketplace change.
#
# Exits 0 on healthy, 1 on any FAIL. Each check prints PASS / FAIL with
# enough context to fix the offending entry.
#
# Usage:
#   bash scripts/marketplace-health.sh
#   bash scripts/marketplace-health.sh --verbose

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MARKETPLACE="$REPO_ROOT/.claude-plugin/marketplace.json"
PLUGINS_DIR="$REPO_ROOT/plugins"
INSTALL_ALL_PATH=""  # detected from the marketplace's bootstrapper plugin

VERBOSE=0
[ "${1:-}" = "--verbose" ] && VERBOSE=1

FAILED=0
fail() {
  echo "  FAIL: $*"
  FAILED=$((FAILED + 1))
}
pass() {
  [ "$VERBOSE" = "1" ] && echo "  PASS: $*"
}
section() {
  echo
  echo "=== $1 ==="
}

# ---------------------------------------------------------------------------
# 1. JSON syntax + top-level schema
# ---------------------------------------------------------------------------
section "marketplace.json structure"

if ! python3 -m json.tool < "$MARKETPLACE" > /dev/null 2>&1; then
  fail "marketplace.json is not valid JSON"
  exit 1
fi
pass "marketplace.json parses as JSON"

python3 - "$MARKETPLACE" <<'PYEOF' || FAILED=$((FAILED + 1))
import json, sys, re
m = json.load(open(sys.argv[1]))
errors = []

if "name" not in m:
    errors.append("missing top-level 'name'")
if "plugins" not in m or not isinstance(m["plugins"], list):
    errors.append("missing/invalid top-level 'plugins' (must be array)")
md = m.get("metadata", {})
if "version" not in md:
    errors.append("missing metadata.version")
elif not re.match(r"^\d+\.\d+\.\d+$", md["version"]):
    errors.append(f"metadata.version not semver: {md['version']!r}")

if errors:
    for e in errors:
        print(f"  FAIL: {e}")
    sys.exit(1)
print("  PASS: top-level keys present + metadata.version semver")
PYEOF

# ---------------------------------------------------------------------------
# 2. Per-plugin entry schema
# ---------------------------------------------------------------------------
section "per-plugin entries"

python3 - "$MARKETPLACE" <<'PYEOF' || FAILED=$((FAILED + 1))
import json, sys, re

m = json.load(open(sys.argv[1]))
plugins = m.get("plugins", [])
errors = 0

required_fields = {"name", "description", "source", "version"}

names_seen = set()
for i, p in enumerate(plugins):
    name = p.get("name", f"<unnamed at index {i}>")
    label = f"plugins[{i}] ({name})"

    missing = required_fields - set(p)
    if missing:
        print(f"  FAIL: {label}: missing fields {sorted(missing)}")
        errors += 1

    if "name" in p:
        if not re.match(r"^[a-z0-9]+(?:-[a-z0-9]+)*$", p["name"]):
            print(f"  FAIL: {label}: name must be kebab-case ([a-z0-9]+(-[a-z0-9]+)*); got {p['name']!r}")
            errors += 1
        if p["name"] in names_seen:
            print(f"  FAIL: {label}: duplicate plugin name {p['name']!r}")
            errors += 1
        names_seen.add(p["name"])

    if "version" in p and not re.match(r"^\d+\.\d+\.\d+$", p["version"]):
        print(f"  FAIL: {label}: version not semver: {p['version']!r}")
        errors += 1

    src = p.get("source", {})
    if not isinstance(src, dict):
        print(f"  FAIL: {label}: source must be an object")
        errors += 1
    else:
        url = src.get("url", "")
        if url and url.startswith("git@"):
            print(f"  FAIL: {label}: source.url uses ssh ({url}); use https:// for public access")
            errors += 1

    # === The bug from v2.1.1 → v2.2.1 ===
    # `dependencies` is a reserved field in Claude Code's marketplace schema
    # and must be a flat array of plugin name strings. Anything else makes
    # /plugin marketplace add fail for every consumer.
    if "dependencies" in p:
        deps = p["dependencies"]
        if not isinstance(deps, list):
            print(
                f"  FAIL: {label}: dependencies must be a flat array of strings, "
                f"got {type(deps).__name__}. This is the v2.1.1 bug — see CLAUDE.md gotchas."
            )
            errors += 1
        else:
            for j, d in enumerate(deps):
                if not isinstance(d, str):
                    print(f"  FAIL: {label}: dependencies[{j}] must be a string, got {type(d).__name__}")
                    errors += 1

    # dev-forge extension — if present, must be array of strings
    if "writes_outside_project_root" in p:
        wopr = p["writes_outside_project_root"]
        if not isinstance(wopr, list) or not all(isinstance(x, str) for x in wopr):
            print(f"  FAIL: {label}: writes_outside_project_root must be an array of strings")
            errors += 1

if errors == 0:
    print(f"  PASS: {len(plugins)} plugin entries — required fields, name format, version, source URL, dependencies shape")
sys.exit(1 if errors > 0 else 0)
PYEOF

# ---------------------------------------------------------------------------
# 3. Plugin paths exist on disk
# ---------------------------------------------------------------------------
section "plugin paths on disk"

python3 - "$MARKETPLACE" "$REPO_ROOT" <<'PYEOF' || FAILED=$((FAILED + 1))
import json, sys
from pathlib import Path

m = json.load(open(sys.argv[1]))
repo_root = Path(sys.argv[2])
errors = 0

for p in m.get("plugins", []):
    src_path = (p.get("source") or {}).get("path")
    if not src_path:
        continue
    abs_path = repo_root / src_path
    if not abs_path.is_dir():
        print(f"  FAIL: {p['name']}: source.path {src_path!r} does not exist on disk")
        errors += 1
        continue
    if not (abs_path / ".claude-plugin" / "plugin.json").is_file():
        print(f"  FAIL: {p['name']}: {src_path}/.claude-plugin/plugin.json missing")
        errors += 1

if errors == 0:
    print(f"  PASS: every plugin entry points at an existing plugin directory")
sys.exit(1 if errors > 0 else 0)
PYEOF

# ---------------------------------------------------------------------------
# 4. plugin.json name + version match marketplace.json entry
# ---------------------------------------------------------------------------
section "plugin.json ↔ marketplace.json consistency"

python3 - "$MARKETPLACE" "$REPO_ROOT" <<'PYEOF' || FAILED=$((FAILED + 1))
import json, sys
from pathlib import Path

m = json.load(open(sys.argv[1]))
repo_root = Path(sys.argv[2])
errors = 0

for entry in m.get("plugins", []):
    src_path = (entry.get("source") or {}).get("path")
    if not src_path:
        continue
    pj_path = repo_root / src_path / ".claude-plugin" / "plugin.json"
    if not pj_path.is_file():
        continue  # already reported in previous check
    pj = json.load(open(pj_path))

    if pj.get("name") != entry["name"]:
        print(f"  FAIL: {entry['name']}: plugin.json name is {pj.get('name')!r}, marketplace says {entry['name']!r}")
        errors += 1
    if pj.get("version") != entry.get("version"):
        print(f"  FAIL: {entry['name']}: plugin.json version is {pj.get('version')!r}, marketplace says {entry.get('version')!r}")
        errors += 1

if errors == 0:
    print(f"  PASS: every plugin's plugin.json name + version matches its marketplace entry")
sys.exit(1 if errors > 0 else 0)
PYEOF

# ---------------------------------------------------------------------------
# 5. Dependencies refer to existing plugin names
# ---------------------------------------------------------------------------
section "dependency references"

python3 - "$MARKETPLACE" <<'PYEOF' || FAILED=$((FAILED + 1))
import json, sys

m = json.load(open(sys.argv[1]))
plugins = m.get("plugins", [])
known = {p.get("name") for p in plugins}
errors = 0

for p in plugins:
    deps = p.get("dependencies", [])
    if not isinstance(deps, list):
        continue  # already reported
    for d in deps:
        if isinstance(d, str) and d not in known:
            print(f"  FAIL: {p['name']}: dependency {d!r} not found in catalog (typo, or did you remove it?)")
            errors += 1

if errors == 0:
    deps_total = sum(len(p.get("dependencies", [])) for p in plugins if isinstance(p.get("dependencies"), list))
    print(f"  PASS: {deps_total} declared dependencies all resolve to known plugins")
sys.exit(1 if errors > 0 else 0)
PYEOF

# ---------------------------------------------------------------------------
# 6. install-all.md is up to date with marketplace.json
# ---------------------------------------------------------------------------
section "install-all.md up-to-date"

GENERATOR="$REPO_ROOT/scripts/generate-install-all.sh"
INSTALL_ALL_DEFAULT="$REPO_ROOT/plugins/forge-init/commands/install-all.md"

if [ -f "$GENERATOR" ] && [ -f "$INSTALL_ALL_DEFAULT" ]; then
  TMPGEN=$(mktemp)
  cp "$INSTALL_ALL_DEFAULT" "$TMPGEN"
  bash "$GENERATOR" > /dev/null 2>&1
  if ! diff -q "$TMPGEN" "$INSTALL_ALL_DEFAULT" > /dev/null 2>&1; then
    fail "install-all.md is stale — run 'bash scripts/generate-install-all.sh' and commit the diff"
    # Restore so we don't leave the working tree dirty
    cp "$TMPGEN" "$INSTALL_ALL_DEFAULT"
  else
    pass "install-all.md matches marketplace.json"
  fi
  rm -f "$TMPGEN"
else
  echo "  SKIP: generator or install-all.md not found"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo
if [ "$FAILED" -gt 0 ]; then
  echo "[health] $FAILED check(s) FAILED — fix before pushing"
  exit 1
fi
echo "[health] all checks passed"
exit 0
