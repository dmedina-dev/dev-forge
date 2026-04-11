#!/usr/bin/env bash
# forge-telegram — get/set the assistant response mode for the channel
#
# Usage:
#   mode.sh get                                     # print current mode
#   mode.sh set <strict|conversational|trust>       # set + print new mode
#
# Mode is stored as a single word in ${STATE_DIR}/mode. The file persists
# across sessions so the choice survives compact/clear/restart. When the
# file doesn't exist, the default is "strict".
#
# Valid modes:
#   strict          — display + ack only; never act on Telegram text
#   conversational  — display + ack + reply conversationally to non-imperatives
#   trust           — display + ack + execute Telegram messages like terminal input

set -euo pipefail

STATE_DIR="${TELEGRAM_STATE_DIR:-${HOME}/.claude/channels/telegram}"
MODE_FILE="${STATE_DIR}/mode"
DEFAULT_MODE="strict"

read_mode() {
  if [[ -f "$MODE_FILE" ]]; then
    local m
    m=$(head -1 "$MODE_FILE" | tr -d '[:space:]')
    case "$m" in
      strict|conversational|trust) echo "$m" ;;
      *) echo "$DEFAULT_MODE" ;;
    esac
  else
    echo "$DEFAULT_MODE"
  fi
}

write_mode() {
  local m="$1"
  mkdir -p "$STATE_DIR"
  chmod 700 "$STATE_DIR" 2>/dev/null || true
  # Direct write — no staging file. The mode file is a single word (~5-15
  # bytes) well under PIPE_BUF, so the write() syscall is atomic at the
  # kernel level; readers either see the old content or the new content,
  # never a partial mix. A staging-and-rename pattern would need its own
  # sandbox allowlist entry (mode.tmp.NNNN) and offers no real benefit
  # for a file of this size.
  printf '%s\n' "$m" > "$MODE_FILE"
  chmod 600 "$MODE_FILE" 2>/dev/null || true
  echo "$m"
}

CMD="${1:-get}"

case "$CMD" in
  get)
    read_mode
    ;;
  set)
    NEW_MODE="${2:-}"
    if [[ -z "$NEW_MODE" ]]; then
      echo "[mode.sh] missing argument — usage: mode.sh set <strict|conversational|trust>" >&2
      exit 2
    fi
    case "$NEW_MODE" in
      strict|conversational|trust)
        write_mode "$NEW_MODE"
        ;;
      *)
        echo "[mode.sh] invalid mode: $NEW_MODE (must be strict|conversational|trust)" >&2
        exit 1
        ;;
    esac
    ;;
  -h|--help)
    sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'
    ;;
  *)
    echo "[mode.sh] unknown subcommand: $CMD — usage: mode.sh {get|set <mode>}" >&2
    exit 2
    ;;
esac
