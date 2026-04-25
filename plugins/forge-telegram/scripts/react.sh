#!/usr/bin/env bash
# forge-telegram — add an emoji reaction to a Telegram message
# Usage: react.sh "<chat_id>" "<message_id>" "<emoji>"
#
# Telegram only accepts a FIXED whitelist of reaction emojis. Anything outside
# that list is silently rejected by the API — you will get ok:true but no
# visible reaction. The full whitelist from the Bot API docs:
#
#   👍 👎 ❤ 🔥 🥰 👏 😁 🤔 🤯 😱 🤬 😢 🎉 🤩 🤮 💩 🙏 👌 🕊 🤡 🥱 🥴 😍
#   🐳 ❤‍🔥 🌚 🌭 💯 🤣 ⚡ 🍌 🏆 💔 🤨 😐 🍓 🍾 💋 🖕 😈 😴 😭 🤓 👻 👨‍💻
#   👀 🎃 🙈 😇 😨 🤝 ✍ 🤗 🫡 🎅 🎄 ☃ 💅 🤪 🗿 🆒 💘 🙉 🦄 😘 💊 🙊 😎
#   👾 🤷‍♂ 🤷 🤷‍♀ 😡
#
# Pass an empty emoji ("") to clear any existing reaction on the message.

set -euo pipefail

CHAT_ID="${1:?Usage: react.sh <chat_id> <message_id> <emoji>}"
MSG_ID="${2:?Usage: react.sh <chat_id> <message_id> <emoji>}"
EMOJI="${3-}"

ENV_FILE="${HOME}/.claude/channels/telegram/.env"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "[react.sh] not configured; run /telegram setup" >&2
  exit 1
fi

TELEGRAM_BOT_TOKEN=$(grep -E '^TELEGRAM_BOT_TOKEN=' "$ENV_FILE" | head -1 | cut -d= -f2-)
if [[ -z "$TELEGRAM_BOT_TOKEN" ]]; then
  echo "[react.sh] missing TELEGRAM_BOT_TOKEN in $ENV_FILE" >&2
  exit 1
fi

# Empty emoji → empty reaction array (clears any existing reaction)
if [[ -z "$EMOJI" ]]; then
  PAYLOAD='[]'
else
  PAYLOAD=$(jq -nc --arg emoji "$EMOJI" '[{type: "emoji", emoji: $emoji}]')
fi

RESP=$(curl -sS -X POST \
  "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/setMessageReaction" \
  --data-urlencode "chat_id=${CHAT_ID}" \
  --data-urlencode "message_id=${MSG_ID}" \
  --data-urlencode "reaction=${PAYLOAD}")

# Mirror every reaction attempt to listen.log for post-mortem diagnosis of
# "the second 👍 didn't show up" cases. Independent of stderr so the trail
# survives even when the caller swallows or doesn't surface stderr.
LOG_FILE="${TELEGRAM_STATE_DIR:-${HOME}/.claude/channels/telegram}/listen.log"
TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

if echo "$RESP" | jq -e '.ok == true' >/dev/null 2>&1; then
  printf '%s [react.sh] ok chat=%s msg=%s emoji=%s\n' "$TS" "$CHAT_ID" "$MSG_ID" "${EMOJI:-<clear>}" >> "$LOG_FILE" 2>/dev/null || true
  exit 0
fi

# Error path. Telegram error shape: {"ok":false,"error_code":N,"description":"...","parameters":{...}}
DESC=$(echo "$RESP" | jq -r '.description // ""' 2>/dev/null)
CODE=$(echo "$RESP" | jq -r '.error_code // ""' 2>/dev/null)
RETRY_AFTER=$(echo "$RESP" | jq -r '.parameters.retry_after // ""' 2>/dev/null)

# Classify common failure modes so the message is actionable instead of "telegram API error: {...}"
case "$DESC" in
  *"REACTION_INVALID"*|*"reaction_invalid"*)
    REASON="emoji '${EMOJI}' is not in Telegram's whitelist (see react.sh header for the valid set)" ;;
  *"MESSAGE_NOT_MODIFIED"*)
    REASON="reaction is already set to '${EMOJI}' on this message — no change needed" ;;
  *"MESSAGE_ID_INVALID"*|*"message to react not found"*|*"MESSAGE_NOT_FOUND"*)
    REASON="message ${MSG_ID} no longer exists or is too old to react to" ;;
  *"Too Many Requests"*|*"FLOOD_WAIT"*)
    REASON="rate-limited by Telegram${RETRY_AFTER:+ — retry after ${RETRY_AFTER}s}" ;;
  *"chat not found"*|*"CHAT_ID_INVALID"*)
    REASON="chat ${CHAT_ID} is not reachable by this bot" ;;
  *)
    REASON="$DESC" ;;
esac

SAFE=$(echo "$RESP" | sed -E 's#bot[0-9]+:[A-Za-z0-9_-]+#bot<REDACTED>#g')
printf '%s [react.sh] FAIL chat=%s msg=%s emoji=%s code=%s reason=%s raw=%s\n' \
  "$TS" "$CHAT_ID" "$MSG_ID" "${EMOJI:-<clear>}" "$CODE" "$REASON" "$SAFE" >> "$LOG_FILE" 2>/dev/null || true

echo "[react.sh] telegram rejected reaction (code=$CODE): $REASON" >&2
echo "[react.sh] raw response: $SAFE" >&2
exit 1
