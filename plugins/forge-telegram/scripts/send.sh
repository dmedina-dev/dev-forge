#!/usr/bin/env bash
# forge-telegram — outbound sender
# Usage: send.sh "<sender>" "<message>"
#
# <sender> identifies the Claude session/role emitting the message
# (e.g. "Main session", "Orchestrator", "Plan Executor"). Always required.
#
# Reads TELEGRAM_BOT_TOKEN and AUTHORIZED_CHAT_ID from ~/.claude/channels/telegram/.env
# (never sources the file — explicit grep parsing for safety).

set -euo pipefail

SENDER="${1:?Usage: send.sh \"<sender>\" \"<message>\"}"
MESSAGE="${2:?Usage: send.sh \"<sender>\" \"<message>\"}"

ENV_FILE="${HOME}/.claude/channels/telegram/.env"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "[send.sh] not configured; run /telegram setup" >&2
  exit 1
fi

# Explicit grep-based parse — never source the env file.
TELEGRAM_BOT_TOKEN=$(grep -E '^TELEGRAM_BOT_TOKEN=' "$ENV_FILE" | head -1 | cut -d= -f2-)
AUTHORIZED_CHAT_ID=$(grep -E '^AUTHORIZED_CHAT_ID=' "$ENV_FILE" | head -1 | cut -d= -f2-)

if [[ -z "$TELEGRAM_BOT_TOKEN" || -z "$AUTHORIZED_CHAT_ID" ]]; then
  echo "[send.sh] missing TELEGRAM_BOT_TOKEN or AUTHORIZED_CHAT_ID in $ENV_FILE" >&2
  exit 1
fi

# Plain-text formatted header — no parse_mode (Markdown breaks on arbitrary content).
FORMATTED="🤖 ${SENDER}
${MESSAGE}"

RESP=$(curl -sS -X POST \
  "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
  --data-urlencode "chat_id=${AUTHORIZED_CHAT_ID}" \
  --data-urlencode "text=${FORMATTED}" \
  --data-urlencode "disable_web_page_preview=true")

if ! echo "$RESP" | jq -e '.ok == true' >/dev/null 2>&1; then
  # Redact token from any error echo that might leak the URL
  SAFE=$(echo "$RESP" | sed -E 's#bot[0-9]+:[A-Za-z0-9_-]+#bot<REDACTED>#g')
  echo "[send.sh] telegram API error: $SAFE" >&2
  exit 1
fi
