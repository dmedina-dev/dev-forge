#!/usr/bin/env bash
#
# ui-forge — validate the Phase 5 handoff bundle for one or all screens.
#
# Thin wrapper around validate-bundle.py so users can pre-approve one stable
# path:
#   bash **/ui-forge/scripts/validate-bundle.sh [screen-id]
# instead of an ad-hoc `python3 <absolute path>` invocation that asks for
# approval on every session.
#
# Run from the project root (parent of .ui-forge/).
#
# Exit codes:
#   0   all checked invariants hold
#   1   at least one violation
#   2   .ui-forge/ not present (run from the wrong directory)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec python3 "$SCRIPT_DIR/validate-bundle.py" "$@"
