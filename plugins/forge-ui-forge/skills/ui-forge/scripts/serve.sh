#!/usr/bin/env bash
#
# ui-forge — launch the dev server.
#
# Thin wrapper around serve.py so users can pre-approve one stable path:
#   bash **/ui-forge/scripts/serve.sh
# instead of an ad-hoc `python3 <absolute path>` invocation that asks for
# approval on every session.
#
# Pass the port as the first argument (default: 4269 inside serve.py).
#
# UIFORGE_PLUGIN_DIR is exported so serve.py can serve the plugin's
# current overlay.js at /assets/overlay.js — users on http:// always get
# the freshest overlay shipped with the plugin install, without running
# refresh-assets.sh per project. file:// keeps using the per-project
# bootstrap copy under .ui-forge/assets/.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
export UIFORGE_PLUGIN_DIR="$SKILL_DIR"
exec python3 "$SCRIPT_DIR/serve.py" "$@"
