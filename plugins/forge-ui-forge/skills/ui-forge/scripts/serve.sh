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

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec python3 "$SCRIPT_DIR/serve.py" "$@"
