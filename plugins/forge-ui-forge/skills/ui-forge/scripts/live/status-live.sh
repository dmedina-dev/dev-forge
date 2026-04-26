#!/usr/bin/env bash
#
# ui-forge — report live proxy status.
#
# Mirrors status.sh but for live mode (PID file .ui-forge/.live-server.pid,
# port 4270 by default).

set -uo pipefail
trap 'exit 0' ERR

PID_FILE="${PWD}/.ui-forge/.live-server.pid"

if [ -f "$PID_FILE" ]; then
  PID="$(cat "$PID_FILE" 2>/dev/null || true)"
  if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
    echo "[ui-forge] live: running (PID $PID) on http://127.0.0.1:4270"
    exit 0
  fi
  echo "[ui-forge] live: stale PID file (process $PID not running) — cleaning up"
  rm -f "$PID_FILE"
fi

echo "[ui-forge] live: not running"
exit 0
