#!/usr/bin/env bash
#
# ui-forge — stop the live proxy.
#
# Mirrors stop.sh but targets .ui-forge/.live-server.pid (live mode) instead
# of .ui-forge/.server.pid (prototype mode). Both can run simultaneously on
# different ports (4269 prototype, 4270 live).
#
# Idempotent: no PID file = friendly message, exit 0.

set -uo pipefail
trap 'exit 0' ERR

PID_FILE="${PWD}/.ui-forge/.live-server.pid"

if [ ! -f "$PID_FILE" ]; then
  echo "[ui-forge] live: no proxy running (no PID file)"
  exit 0
fi

PID="$(cat "$PID_FILE" 2>/dev/null || true)"

if [ -z "$PID" ]; then
  echo "[ui-forge] live: PID file empty — cleaning up"
  rm -f "$PID_FILE"
  exit 0
fi

if kill -0 "$PID" 2>/dev/null; then
  kill "$PID" 2>/dev/null
  echo "[ui-forge] live: stopped proxy (PID $PID)"
else
  echo "[ui-forge] live: PID $PID not running — cleaning up stale PID file"
fi

rm -f "$PID_FILE"
exit 0
