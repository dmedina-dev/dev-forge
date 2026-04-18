#!/usr/bin/env bash
#
# ui-forge — report dev server status.
#
# Same rationale as stop.sh / serve.sh: a stable, pre-approvable path so
# no ad-hoc bash is needed to check whether the server is up.

set -uo pipefail
trap 'exit 0' ERR

PID_FILE="${PWD}/.ui-forge/.server.pid"

if [ -f "$PID_FILE" ]; then
  PID="$(cat "$PID_FILE" 2>/dev/null || true)"
  if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
    echo "[ui-forge] running (PID $PID) on http://127.0.0.1:4269"
    exit 0
  fi
  echo "[ui-forge] stale PID file (process $PID not running) — cleaning up"
  rm -f "$PID_FILE"
fi

echo "[ui-forge] not running"
exit 0
