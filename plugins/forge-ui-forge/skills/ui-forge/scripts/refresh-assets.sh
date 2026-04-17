#!/usr/bin/env bash
#
# ui-forge — force-refresh runtime assets in <project>/.ui-forge/assets/
#
# Copies every file from the plugin's assets/ directory into the consumer's
# .ui-forge/assets/, OVERWRITING existing copies. Does not touch config,
# registry data, screens, fixtures, or feedback — only the executable assets
# (overlay.js and any future siblings).
#
# Usage (invoked by the ui-forge skill, from the consumer project root):
#   bash "${CLAUDE_PLUGIN_ROOT}/skills/ui-forge/scripts/refresh-assets.sh"

set -uo pipefail
trap 'exit 0' ERR

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-}"
if [ -z "$PLUGIN_ROOT" ]; then
  echo "[ui-forge] CLAUDE_PLUGIN_ROOT not set — cannot locate skill assets." >&2
  exit 0
fi

SRC_DIR="${PLUGIN_ROOT}/skills/ui-forge/assets"
TARGET_ROOT="${PWD}/.ui-forge"
TARGET_DIR="${TARGET_ROOT}/assets"

if [ ! -d "$TARGET_ROOT" ]; then
  echo "[ui-forge] no .ui-forge/ directory found — run init-registry.sh first." >&2
  exit 0
fi

if [ ! -d "$SRC_DIR" ]; then
  echo "[ui-forge] plugin assets directory missing: $SRC_DIR" >&2
  exit 0
fi

mkdir -p "$TARGET_DIR"

count=0
for src in "$SRC_DIR"/*; do
  [ -f "$src" ] || continue
  name="$(basename "$src")"
  dst="$TARGET_DIR/$name"
  if [ -f "$dst" ] && cmp -s "$src" "$dst"; then
    echo "[ui-forge] unchanged: $name"
  else
    cp "$src" "$dst"
    lines="$(wc -l < "$dst" | tr -d ' ')"
    echo "[ui-forge] refreshed: $name ($lines lines)"
    count=$((count + 1))
  fi
done

if [ "$count" -eq 0 ]; then
  echo "[ui-forge] assets already up to date."
else
  echo "[ui-forge] refreshed $count asset(s). Hard-reload the browser (Cmd+Shift+R) to pick them up."
fi

exit 0
