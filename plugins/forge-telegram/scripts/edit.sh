#!/usr/bin/env bash
# forge-telegram — edit a message the bot previously sent
# Usage: edit.sh "<chat_id>" "<message_id>" "<new_text>"
#
# Only works on messages authored by the bot itself. Edits don't trigger push
# notifications on the recipient's device — useful for "working…" → "done"
# progress updates, but send a fresh message instead when you want a ping.

set -euo pipefail

CHAT_ID="${1:?Usage: edit.sh <chat_id> <message_id> <new_text>}"
MSG_ID="${2:?Usage: edit.sh <chat_id> <message_id> <new_text>}"
NEW_TEXT="${3:?Usage: edit.sh <chat_id> <message_id> <new_text>}"

ENV_FILE="${HOME}/.claude/channels/telegram/.env"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "[edit.sh] not configured; run /telegram setup" >&2
  exit 1
fi

TELEGRAM_BOT_TOKEN=$(grep -E '^TELEGRAM_BOT_TOKEN=' "$ENV_FILE" | head -1 | cut -d= -f2-)
if [[ -z "$TELEGRAM_BOT_TOKEN" ]]; then
  echo "[edit.sh] missing TELEGRAM_BOT_TOKEN in $ENV_FILE" >&2
  exit 1
fi

RESP=$(curl -sS -X POST \
  "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/editMessageText" \
  --data-urlencode "chat_id=${CHAT_ID}" \
  --data-urlencode "message_id=${MSG_ID}" \
  --data-urlencode "text=${NEW_TEXT}" \
  --data-urlencode "disable_web_page_preview=true")

if ! echo "$RESP" | jq -e '.ok == true' >/dev/null 2>&1; then
  SAFE=$(echo "$RESP" | sed -E 's#bot[0-9]+:[A-Za-z0-9_-]+#bot<REDACTED>#g')
  echo "[edit.sh] telegram API error: $SAFE" >&2
  exit 1
fi
