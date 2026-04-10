#!/usr/bin/env bash
# Proactive QA — Telegram Notification Script
# Usage: bash telegram-notify.sh "<type>" "<message>"
# Types: explore, fix-ok, fix-fail, cycle-done, error
#
# Credential resolution order:
#   1. ~/.claude/channels/telegram/.env   (user-level, from forge-telegram)
#      Keys: TELEGRAM_BOT_TOKEN + AUTHORIZED_CHAT_ID
#   2. plugin-root .env                    (legacy)
#   3. project .env                        (legacy, uses TELEGRAM_CHAT_ID)
#
# If no credentials are found, logs to stderr and exits 0 silently.
trap 'exit 0' ERR

TYPE="${1:-info}"
MESSAGE="${2:-Sin mensaje}"

# 1) forge-telegram user-level env (primary source)
USER_ENV="${HOME}/.claude/channels/telegram/.env"
if [[ -f "$USER_ENV" ]]; then
  # Explicit parsing — never `source` untrusted files
  TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-$(grep -E '^TELEGRAM_BOT_TOKEN=' "$USER_ENV" | head -1 | cut -d= -f2-)}"
  AUTHORIZED_CHAT_ID_RAW="$(grep -E '^AUTHORIZED_CHAT_ID=' "$USER_ENV" | head -1 | cut -d= -f2-)"
  TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:-$AUTHORIZED_CHAT_ID_RAW}"
fi

# 2) Plugin-root .env (legacy fallback)
PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
for envfile in "$PLUGIN_ROOT/.env" ".env"; do
  if [[ -f "$envfile" ]] && { [[ -z "${TELEGRAM_BOT_TOKEN:-}" ]] || [[ -z "${TELEGRAM_CHAT_ID:-}" ]]; }; then
    set -a
    # shellcheck disable=SC1090
    source "$envfile" 2>/dev/null || true
    set +a
    break
  fi
done

if [[ -z "${TELEGRAM_BOT_TOKEN:-}" ]] || [[ -z "${TELEGRAM_CHAT_ID:-}" ]]; then
  echo "[proactive-qa] Telegram not configured (no TELEGRAM_BOT_TOKEN / chat_id in ~/.claude/channels/telegram/.env or project .env). Skipping." >&2
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
