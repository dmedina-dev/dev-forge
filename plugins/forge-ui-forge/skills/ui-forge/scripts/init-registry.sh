#!/usr/bin/env bash
#
# ui-forge — idempotent bootstrap for <project>/.ui-forge/
#
# Safe to re-run. Creates missing directories and files; never overwrites
# existing user state (tokens.json, manifest.json, config.json, overlay.js).
#
# Usage (invoked by the ui-forge skill, from the consumer project root):
#   bash "${CLAUDE_PLUGIN_ROOT}/skills/ui-forge/scripts/init-registry.sh"

set -uo pipefail
trap 'exit 0' ERR

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-}"
if [ -z "$PLUGIN_ROOT" ]; then
  echo "[ui-forge] CLAUDE_PLUGIN_ROOT not set — cannot locate skill assets." >&2
  exit 0
fi

SKILL_DIR="${PLUGIN_ROOT}/skills/ui-forge"
TEMPLATE_TOKENS="${SKILL_DIR}/templates/tokens.default.json"
ASSET_OVERLAY="${SKILL_DIR}/assets/overlay.js"

TARGET_ROOT="${PWD}/.ui-forge"

if [ ! -d "$TARGET_ROOT" ]; then
  echo "[ui-forge] creating .ui-forge/ at ${TARGET_ROOT}"
fi

mkdir -p "$TARGET_ROOT/assets"
mkdir -p "$TARGET_ROOT/registry/components"
mkdir -p "$TARGET_ROOT/registry/fixtures"
mkdir -p "$TARGET_ROOT/screens"

# config.json — only created on first run
if [ ! -f "$TARGET_ROOT/config.json" ]; then
  cat > "$TARGET_ROOT/config.json" <<'JSON'
{
  "version": 1,
  "naming": "kebab-case"
}
JSON
  echo "[ui-forge] wrote config.json"
fi

# registry/manifest.json — empty registry
if [ ! -f "$TARGET_ROOT/registry/manifest.json" ]; then
  cat > "$TARGET_ROOT/registry/manifest.json" <<'JSON'
{
  "schemaVersion": 1,
  "components": []
}
JSON
  echo "[ui-forge] wrote registry/manifest.json"
fi

# registry/fixtures/index.json — empty index
if [ ! -f "$TARGET_ROOT/registry/fixtures/index.json" ]; then
  cat > "$TARGET_ROOT/registry/fixtures/index.json" <<'JSON'
{
  "fixtures": []
}
JSON
  echo "[ui-forge] wrote registry/fixtures/index.json"
fi

# registry/tokens.json — copy from template only if missing
if [ ! -f "$TARGET_ROOT/registry/tokens.json" ]; then
  if [ -f "$TEMPLATE_TOKENS" ]; then
    cp "$TEMPLATE_TOKENS" "$TARGET_ROOT/registry/tokens.json"
    echo "[ui-forge] seeded registry/tokens.json from defaults"
  else
    echo "[ui-forge] warning: template tokens.default.json not found at $TEMPLATE_TOKENS" >&2
  fi
fi

# assets/overlay.js — copy from plugin only if missing so HTML uses stable relative path
if [ ! -f "$TARGET_ROOT/assets/overlay.js" ]; then
  if [ -f "$ASSET_OVERLAY" ]; then
    cp "$ASSET_OVERLAY" "$TARGET_ROOT/assets/overlay.js"
    echo "[ui-forge] copied overlay.js into .ui-forge/assets/"
  else
    echo "[ui-forge] warning: overlay.js not found at $ASSET_OVERLAY" >&2
  fi
fi

echo "[ui-forge] bootstrap complete."
exit 0
