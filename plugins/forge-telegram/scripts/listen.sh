#!/usr/bin/env bash
# forge-telegram — long-poll listener for Monitor tool
# Usage: bash listen.sh
#
# Long-polls Telegram getUpdates in a tight loop. Emits one JSON line per
# authorized inbound message to stdout. Designed to be wrapped by the Monitor
# tool: Monitor reads each stdout line as a separate event.
#
# Silence (no messages) = zero output = zero events delivered to the session.
#
# Voice messages are transcribed inline by calling transcribe.sh and emitted
# as a single text event with a [voice] prefix.
#
# Strict filter: only messages from AUTHORIZED_CHAT_ID are emitted.
#
# Does NOT set -e — we want to survive transient curl/network errors and retry.

set -uo pipefail

STATE_DIR="${HOME}/.claude/channels/telegram"
ENV_FILE="${STATE_DIR}/.env"
OFFSET_FILE="${STATE_DIR}/.offset"
LOG_FILE="${STATE_DIR}/listen.log"
EMIT_LOG="${STATE_DIR}/emit.log"
INBOX_DIR="${STATE_DIR}/inbox"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TRANSCRIBE="${SCRIPT_DIR}/transcribe.sh"

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

# ── Emit helper ─────────────────────────────────────────────
# Writes one JSON event to stdout. Refuses to emit:
#   - empty strings
#   - lines whose first character is not '{' (i.e. not a JSON object)
#
# Uses `printf` (a bash builtin) for the actual write — builtins bypass
# stdio buffering and write directly via write(), so we get unbuffered
# output without needing a stdbuf/gstdbuf wrapper.
#
# Every accepted emission is also mirrored (timestamped) to $EMIT_LOG so
# the developer can correlate what listen.sh sent vs what the session saw.
emit_event() {
  local line="$1"

  if [[ -z "$line" ]]; then
    echo "[emit] refused empty line" >> "$LOG_FILE"
    return 0
  fi
  if [[ "${line:0:1}" != "{" ]]; then
    echo "[emit] refused non-object: ${line:0:120}" >> "$LOG_FILE"
    return 0
  fi

  printf '%s %s\n' "$(date '+%Y-%m-%dT%H:%M:%S')" "$line" >> "$EMIT_LOG"
  printf '%s\n' "$line"
}

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
  # allowed_updates=["message"] — covers text, voice, photo, and every other
  # .message.* sub-field; media fields arrive attached to a message object.
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
    UPD_ID=$(echo "$UPDATE" | jq '.update_id')
    echo "$((UPD_ID + 1))" > "$OFFSET_FILE"

    CHAT_ID=$(echo "$UPDATE" | jq -r '.message.chat.id // empty')
    if [[ -z "$CHAT_ID" || "$CHAT_ID" != "$AUTHORIZED_CHAT_ID" ]]; then
      continue
    fi

    MSG_ID=$(echo "$UPDATE" | jq '.message.message_id')

    # ── Text message ──────────────────────────────────────
    MSG_TEXT=$(echo "$UPDATE" | jq -r '.message.text // empty')
    if [[ -n "$MSG_TEXT" ]]; then
      EVENT=$(echo "$UPDATE" | jq -c '{type: "text", text: .message.text, msg_id: .message.message_id}')
      emit_event "$EVENT"
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
      EVENT=$(jq -nc --arg text "$TEXT_OUT" --argjson msg_id "$MSG_ID" \
        '{type: "text", text: $text, msg_id: $msg_id, source: "voice"}')
      emit_event "$EVENT"
      continue
    fi

    # ── Photo message: download + emit with image_path ────
    HAS_PHOTO=$(echo "$UPDATE" | jq '(.message.photo // []) | length')
    if [[ "$HAS_PHOTO" -gt 0 ]]; then
      # Pick the LAST entry in .message.photo — Telegram returns size variants
      # in ascending resolution order, so the last element is the largest.
      PHOTO_FILE_ID=$(echo "$UPDATE" | jq -r '.message.photo[-1].file_id')
      PHOTO_UNIQUE_ID=$(echo "$UPDATE" | jq -r '.message.photo[-1].file_unique_id // empty')
      PHOTO_CAPTION=$(echo "$UPDATE" | jq -r '.message.caption // ""')

      # Resolve the file path (Telegram gives us a relative path into its CDN).
      FILE_RESP=$(curl -sS --max-time 10 \
        "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getFile?file_id=${PHOTO_FILE_ID}" 2>/dev/null || echo '{"ok":false}')

      PHOTO_EMITTED=0
      if echo "$FILE_RESP" | jq -e '.ok == true' >/dev/null 2>&1; then
        FILE_PATH=$(echo "$FILE_RESP" | jq -r '.result.file_path')
        EXT="${FILE_PATH##*.}"
        # Fallback extension if none in the path
        [[ "$EXT" == "$FILE_PATH" ]] && EXT="jpg"
        mkdir -p "$INBOX_DIR"
        LOCAL_PATH="${INBOX_DIR}/$(date +%s)-${PHOTO_UNIQUE_ID:-$MSG_ID}.${EXT}"

        if curl -sS --max-time 30 \
             "https://api.telegram.org/file/bot${TELEGRAM_BOT_TOKEN}/${FILE_PATH}" \
             -o "$LOCAL_PATH" 2>/dev/null; then
          # Emit text = caption if present, else a neutral placeholder.
          # The image_path field is the absolute path the assistant can Read().
          EVENT=$(jq -nc \
            --arg text "${PHOTO_CAPTION:-(photo)}" \
            --arg image_path "$LOCAL_PATH" \
            --argjson msg_id "$MSG_ID" \
            '{type: "text", text: $text, image_path: $image_path, msg_id: $msg_id, source: "photo"}')
          emit_event "$EVENT"
          PHOTO_EMITTED=1
        fi
      fi

      if [[ "$PHOTO_EMITTED" -eq 0 ]]; then
        # Photo arrived but getFile / download failed. Emit a graceful
        # placeholder so the assistant knows something came in, rather
        # than silently dropping it.
        echo "[listen.sh] photo download failed for msg_id=${MSG_ID}" >> "$LOG_FILE"
        EVENT=$(jq -nc --argjson msg_id "$MSG_ID" \
          '{type: "text", text: "(photo — download failed)", msg_id: $msg_id, source: "photo"}')
        emit_event "$EVENT"
      fi
      continue
    fi

    # ── Other media (sticker, doc, etc.) ──────────────────
    echo "[listen.sh] unsupported message type, msg_id=${MSG_ID}" >> "$LOG_FILE"
  done < <(echo "$RESP" | jq -c '.result[]')
done
