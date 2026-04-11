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

if ! echo "$RESP" | jq -e '.ok == true' >/dev/null 2>&1; then
  SAFE=$(echo "$RESP" | sed -E 's#bot[0-9]+:[A-Za-z0-9_-]+#bot<REDACTED>#g')
  echo "[react.sh] telegram API error: $SAFE" >&2
  exit 1
fi
