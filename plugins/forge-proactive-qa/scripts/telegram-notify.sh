#!/usr/bin/env bash
# Proactive QA — Telegram Notification Fallback Script
# Usage: bash telegram-notify.sh "<type>" "<message>"
# Types: explore, fix-ok, fix-fail, cycle-done, error
#
# This is the FALLBACK for when forge-channels-telegram is not installed.
# When the MCP reply tool is available, notifications go through the channel instead.
#
# Requires env vars: TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID
# If not set, logs to stderr and exits silently.
trap 'exit 0' ERR

TYPE="${1:-info}"
MESSAGE="${2:-Sin mensaje}"

# Load .env — try plugin root first, then project root
PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
for envfile in "$PLUGIN_ROOT/.env" ".env"; do
  if [[ -f "$envfile" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "$envfile" 2>/dev/null || true
    set +a
    break
  fi
done

if [[ -z "${TELEGRAM_BOT_TOKEN:-}" ]] || [[ -z "${TELEGRAM_CHAT_ID:-}" ]]; then
  echo "[proactive-qa] Telegram no configurado (TELEGRAM_BOT_TOKEN / TELEGRAM_CHAT_ID). Skipping." >&2
  exit 0
fi

# Emoji by type
case "$TYPE" in
  explore)    EMOJI="🔍" ;;
  fix-ok)     EMOJI="✅" ;;
  fix-fail)   EMOJI="❌" ;;
  cycle-done) EMOJI="🏁" ;;
  error)      EMOJI="🚨" ;;
  *)          EMOJI="ℹ️" ;;
esac

# Get current branch
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

# Build the Telegram message
TEXT="${EMOJI} *Proactive QA* — \`${TYPE}\`
📂 Branch: \`${BRANCH}\`

${MESSAGE}"

# Send via Telegram Bot API
RESPONSE=$(curl -s -X POST \
  "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
  -d "chat_id=${TELEGRAM_CHAT_ID}" \
  -d "text=${TEXT}" \
  -d "parse_mode=Markdown" \
  -d "disable_web_page_preview=true" \
  2>&1)

# Check if successful
if echo "$RESPONSE" | grep -q '"ok":true'; then
  echo "[proactive-qa] Telegram notification sent: ${TYPE}" >&2
else
  echo "[proactive-qa] Telegram send failed: ${RESPONSE}" >&2
fi
