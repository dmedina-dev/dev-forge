#!/usr/bin/env bash
#
# ui-forge — launch the LIVE proxy (HTTP+WebSocket reverse proxy that injects
# the overlay into responses from an existing dev server).
#
# Mirrors serve.sh as a thin wrapper around live.py so users can pre-approve
# one stable path:
#   bash **/ui-forge/scripts/live/live.sh
#
# Preflights `import aiohttp`. If aiohttp is not importable, prints an
# actionable error and aborts BEFORE starting the proxy (live mode requires
# the dependency; prototype mode does not).
#
# Pass-through arguments (consumed by live.py):
#   --target <url>     required. Upstream dev server (e.g. http://localhost:3000).
#   --port <n>         default: 4270.
#   --name <slug>      default: ISO timestamp; sets the directory name under
#                      .ui-forge/live/ where round-NN.json files are written.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if ! python3 -c 'import aiohttp' 2>/dev/null; then
  echo "[ui-forge] live mode requires aiohttp. Install with: pip install aiohttp" >&2
  exit 1
fi

exec python3 "$SCRIPT_DIR/live.py" "$@"
