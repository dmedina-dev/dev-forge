#!/usr/bin/env bash
#
# ui-forge — stop the running dev server.
#
# Kills the PID recorded in .ui-forge/.server.pid and removes the file.
# Idempotent: no server running = friendly message, exit 0.
#
# This is a dedicated script so users can pre-approve one stable path:
#   bash **/ui-forge/scripts/stop.sh
# instead of ad-hoc inline bash that triggers an approval dialog every time.

set -uo pipefail
trap 'exit 0' ERR

PID_FILE="${PWD}/.ui-forge/.server.pid"

if [ ! -f "$PID_FILE" ]; then
  echo "[ui-forge] no server running (no PID file)"
  exit 0
fi

PID="$(cat "$PID_FILE" 2>/dev/null || true)"

if [ -z "$PID" ]; then
  echo "[ui-forge] PID file empty — cleaning up"
  rm -f "$PID_FILE"
  exit 0
fi

if kill -0 "$PID" 2>/dev/null; then
  kill "$PID" 2>/dev/null
  echo "[ui-forge] stopped server (PID $PID)"
else
  echo "[ui-forge] PID $PID not running — cleaning up stale PID file"
fi

rm -f "$PID_FILE"
exit 0
