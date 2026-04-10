#!/usr/bin/env bash
# forge-telegram — long-poll listener for Monitor tool
# Usage: bash listen.sh
#
# Long-polls Telegram getUpdates in a tight loop. Emits one JSON line per
# authorized inbound message to stdout (line-buffered). Designed to be wrapped
# by the Monitor tool: Monitor reads each stdout line as a separate event.
#
# Silence (no messages) = zero output = zero tokens consumed by the wrapping agent.
#
# Voice messages are transcribed inline by calling transcribe.sh and emitted as
# a single text event with a [voice] prefix. The wrapping Haiku teammate never
# sees voice events — only text.
#
# Strict filter: only messages from AUTHORIZED_CHAT_ID are emitted.
#
# Does NOT set -e — we want to survive transient curl/network errors and retry.

set -uo pipefail

STATE_DIR="${HOME}/.claude/channels/telegram"
ENV_FILE="${STATE_DIR}/.env"
OFFSET_FILE="${STATE_DIR}/.offset"
LOG_FILE="${STATE_DIR}/listen.log"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TRANSCRIBE="${SCRIPT_DIR}/transcribe.sh"

# ── Line-buffered stdout ────────────────────────────────────
# Portable across Linux (stdbuf) and macOS (gstdbuf from Homebrew coreutils).
# jq -c is already line-buffered in -c mode, so this mostly handles any bare
# echoes we might do for log lines.
if command -v stdbuf >/dev/null 2>&1; then
  exec 1> >(stdbuf -oL cat)
elif command -v gstdbuf >/dev/null 2>&1; then
  exec 1> >(gstdbuf -oL cat)
else
  echo "[listen.sh] warning: stdbuf not found; output may buffer. Install coreutils." >&2
fi

# ── Load env ────────────────────────────────────────────────
if [[ ! -f "$ENV_FILE" ]]; then
  echo "[listen.sh] not configured; run /telegram setup" >&2
  exit 1
fi

TELEGRAM_BOT_TOKEN=$(grep -E '^TELEGRAM_BOT_TOKEN=' "$ENV_FILE" | head -1 | cut -d= -f2-)
AUTHORIZED_CHAT_ID=$(grep -E '^AUTHORIZED_CHAT_ID=' "$ENV_FILE" | head -1 | cut -d= -f2-)

if [[ -z "$TELEGRAM_BOT_TOKEN" ]]; then
  echo "[listen.sh] missing TELEGRAM_BOT_TOKEN" >&2
  exit 1
fi
if [[ -z "$AUTHORIZED_CHAT_ID" ]]; then
  echo "[listen.sh] missing AUTHORIZED_CHAT_ID — run /telegram setup" >&2
  exit 1
fi

# ── Prime offset on first run ───────────────────────────────
# Skip any messages that arrived BEFORE the listener started so we don't
# replay old history from previous sessions.
if [[ ! -f "$OFFSET_FILE" ]]; then
  PRIME=$(curl -sS --max-time 10 \
    "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getUpdates?offset=-1&limit=1" 2>/dev/null || echo '{"ok":true,"result":[]}')
  LATEST_UID=$(echo "$PRIME" | jq '[.result[].update_id] | max // 0')
  echo "$((LATEST_UID + 1))" > "$OFFSET_FILE"
fi

# ── Main loop ───────────────────────────────────────────────
FAIL_COUNT=0

while true; do
  OFFSET=$(cat "$OFFSET_FILE" 2>/dev/null || echo 0)

  # curl stderr is intentionally discarded (never logged) because it includes
  # the full URL with the bot token on errors. Our own echoes to $LOG_FILE
  # are token-free.
  if ! RESP=$(curl -sS --max-time 40 \
       "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getUpdates?offset=${OFFSET}&timeout=25&allowed_updates=%5B%22message%22%5D" 2>/dev/null); then
    FAIL_COUNT=$((FAIL_COUNT + 1))
    echo "[listen.sh] curl failed ($FAIL_COUNT); retrying in 5s" >> "$LOG_FILE"
    sleep 5
    continue
  fi

  if ! echo "$RESP" | jq -e '.ok == true' >/dev/null 2>&1; then
    FAIL_COUNT=$((FAIL_COUNT + 1))
    echo "[listen.sh] Telegram API error ($FAIL_COUNT)" >> "$LOG_FILE"
    sleep 5
    continue
  fi

  FAIL_COUNT=0

  COUNT=$(echo "$RESP" | jq '.result | length')
  if [[ "$COUNT" -eq 0 ]]; then
    continue
  fi

  # Iterate each update. Advance offset after EVERY update (even filtered ones)
  # so we never reprocess them.
  while IFS= read -r UPDATE; do
    UID=$(echo "$UPDATE" | jq '.update_id')
    echo "$((UID + 1))" > "$OFFSET_FILE"

    CHAT_ID=$(echo "$UPDATE" | jq -r '.message.chat.id // empty')
    if [[ -z "$CHAT_ID" || "$CHAT_ID" != "$AUTHORIZED_CHAT_ID" ]]; then
      continue
    fi

    MSG_ID=$(echo "$UPDATE" | jq '.message.message_id')

    # ── Text message ──────────────────────────────────────
    MSG_TEXT=$(echo "$UPDATE" | jq -r '.message.text // empty')
    if [[ -n "$MSG_TEXT" ]]; then
      echo "$UPDATE" | jq -c '{type: "text", text: .message.text, msg_id: .message.message_id}'
      continue
    fi

    # ── Voice message: transcribe inline ──────────────────
    VOICE_FILE_ID=$(echo "$UPDATE" | jq -r '.message.voice.file_id // empty')
    if [[ -n "$VOICE_FILE_ID" ]]; then
      # -e is NOT set in this script (we only use -u -o pipefail), so a
      # non-zero exit from the command substitution will NOT abort the loop.
      # $? captures the exit code of the last command, i.e. the transcribe.
      TRANSCRIPT=$(bash "$TRANSCRIBE" "$VOICE_FILE_ID" 2>>"$LOG_FILE")
      EXIT_CODE=$?
      case $EXIT_CODE in
        0)
          TEXT_OUT="[voice] ${TRANSCRIPT}"
          ;;
        2)
          TEXT_OUT="[voice message received — OPENAI_API_KEY not set]"
          ;;
        3)
          TEXT_OUT="[voice message too large (>25 MB)]"
          ;;
        *)
          TEXT_OUT="[voice transcription failed — check listen.log]"
          ;;
      esac
      # jq -nc builds a safe single-line JSON object
      jq -nc --arg text "$TEXT_OUT" --argjson msg_id "$MSG_ID" \
        '{type: "text", text: $text, msg_id: $msg_id, source: "voice"}'
      continue
    fi

    # ── Other media (sticker, photo, doc, etc.) ───────────
    echo "[listen.sh] unsupported message type, msg_id=${MSG_ID}" >> "$LOG_FILE"
  done < <(echo "$RESP" | jq -c '.result[]')
done
