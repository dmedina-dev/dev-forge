#!/usr/bin/env bash
# forge-telegram — one-shot interactive setup
# Usage: bash setup.sh
#
# Creates ~/.claude/channels/telegram/ and populates .env with:
#   TELEGRAM_BOT_TOKEN    (required — validated via getMe)
#   OPENAI_API_KEY        (optional — voice transcription disabled if blank)
#   AUTHORIZED_CHAT_ID    (paired via 6-digit PIN — only this chat is listened to)
#
# Idempotent: if everything is already set and the token still validates,
# prints masked status and exits 0 without prompting.
#
# Uses a dedicated .pairing-offset file (not the listener's .offset) to avoid
# races if someone has listen.sh running in another terminal.

set -euo pipefail

STATE_DIR="${HOME}/.claude/channels/telegram"
ENV_FILE="${STATE_DIR}/.env"
PAIRING_OFFSET_FILE="${STATE_DIR}/.pairing-offset"

mkdir -p "$STATE_DIR"
chmod 700 "$STATE_DIR"
touch "$ENV_FILE"
chmod 600 "$ENV_FILE"

mask() {
  local s="${1:-}"
  local len=${#s}
  if (( len <= 8 )); then
    echo "********"
  else
    echo "${s:0:4}…${s: -4}"
  fi
}

# Read a single key from env file (grep-based, never source)
get_env_key() {
  grep -E "^$1=" "$ENV_FILE" 2>/dev/null | head -1 | cut -d= -f2-
}

# Atomically write or replace a single key
set_env_key() {
  local key="$1"
  local value="$2"
  local tmp="${ENV_FILE}.tmp.$$"
  grep -v "^${key}=" "$ENV_FILE" > "$tmp" 2>/dev/null || true
  echo "${key}=${value}" >> "$tmp"
  mv "$tmp" "$ENV_FILE"
  chmod 600 "$ENV_FILE"
}

# Validate a bot token via getMe
validate_token() {
  local token="$1"
  local resp
  resp=$(curl -sS --max-time 10 "https://api.telegram.org/bot${token}/getMe" 2>/dev/null) || return 1
  echo "$resp" | jq -e '.ok == true' >/dev/null 2>&1
}

TELEGRAM_BOT_TOKEN=$(get_env_key TELEGRAM_BOT_TOKEN)
OPENAI_API_KEY=$(get_env_key OPENAI_API_KEY)
AUTHORIZED_CHAT_ID=$(get_env_key AUTHORIZED_CHAT_ID)

# ───────────────────────────────────────────────────────────
# Idempotency check
# ───────────────────────────────────────────────────────────
if [[ -n "$TELEGRAM_BOT_TOKEN" && -n "$AUTHORIZED_CHAT_ID" ]]; then
  if validate_token "$TELEGRAM_BOT_TOKEN"; then
    echo ""
    echo "✅ forge-telegram already configured"
    echo "  Token:          $(mask "$TELEGRAM_BOT_TOKEN")"
    echo "  Chat ID:        $(mask "$AUTHORIZED_CHAT_ID")"
    if [[ -n "$OPENAI_API_KEY" ]]; then
      echo "  Voice (Whisper): enabled  $(mask "$OPENAI_API_KEY")"
    else
      echo "  Voice (Whisper): disabled (no OPENAI_API_KEY)"
    fi
    echo ""
    echo "Run /telegram start to begin listening."
    exit 0
  else
    echo "⚠️  Existing token failed validation — will re-prompt"
    TELEGRAM_BOT_TOKEN=""
  fi
fi

# ───────────────────────────────────────────────────────────
# Token prompt
# ───────────────────────────────────────────────────────────
if [[ -z "$TELEGRAM_BOT_TOKEN" ]]; then
  echo ""
  echo "── Telegram bot token ───────────────────────────────"
  echo "Get one from @BotFather. Format: 123456789:AA…"
  read -r -s -p "Paste TELEGRAM_BOT_TOKEN: " NEW_TOKEN
  echo ""
  NEW_TOKEN="${NEW_TOKEN// /}"
  if [[ -z "$NEW_TOKEN" ]]; then
    echo "❌ No token provided — aborting" >&2
    exit 1
  fi
  if ! validate_token "$NEW_TOKEN"; then
    echo "❌ Token failed getMe validation — aborting" >&2
    exit 1
  fi
  set_env_key TELEGRAM_BOT_TOKEN "$NEW_TOKEN"
  TELEGRAM_BOT_TOKEN="$NEW_TOKEN"
  echo "✓ Token saved and validated"
fi

# ───────────────────────────────────────────────────────────
# OpenAI key (optional)
# ───────────────────────────────────────────────────────────
if [[ -z "$OPENAI_API_KEY" ]]; then
  echo ""
  echo "── OpenAI API key (optional, for voice transcription) ──"
  read -r -s -p "Paste OPENAI_API_KEY (ENTER to skip): " NEW_OAI
  echo ""
  NEW_OAI="${NEW_OAI// /}"
  if [[ -n "$NEW_OAI" ]]; then
    set_env_key OPENAI_API_KEY "$NEW_OAI"
    OPENAI_API_KEY="$NEW_OAI"
    echo "✓ OpenAI key saved — voice transcription enabled"
  else
    echo "⏭  Skipped — voice transcription disabled"
  fi
fi

# ───────────────────────────────────────────────────────────
# PIN pairing — only if AUTHORIZED_CHAT_ID is missing
# ───────────────────────────────────────────────────────────
if [[ -z "$AUTHORIZED_CHAT_ID" ]]; then
  # Generate a 6-digit PIN
  PIN=$(printf "%06d" $((RANDOM * RANDOM % 1000000)))

  # Prime the pairing offset with the current latest update_id + 1,
  # so we only consider updates that arrive AFTER pairing starts.
  PRIME=$(curl -sS --max-time 10 \
    "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getUpdates?offset=-1&limit=1" 2>/dev/null || echo '{"ok":true,"result":[]}')
  LATEST_UID=$(echo "$PRIME" | jq '[.result[].update_id] | max // 0')
  INITIAL_OFFSET=$((LATEST_UID + 1))
  echo "$INITIAL_OFFSET" > "$PAIRING_OFFSET_FILE"

  echo ""
  echo "────────────────────────────────────────────────────"
  echo "  🔐  PAIRING PIN:  ${PIN}"
  echo "────────────────────────────────────────────────────"
  echo ""
  echo "On your phone, open the Telegram chat with your bot"
  echo "and send this exact message:"
  echo ""
  echo "    ${PIN}"
  echo ""
  echo "Waiting up to 5 minutes for the PIN..."
  echo ""

  DEADLINE=$((SECONDS + 300))
  MATCHED_CHAT_ID=""

  while (( SECONDS < DEADLINE )); do
    OFFSET=$(cat "$PAIRING_OFFSET_FILE")
    RESP=$(curl -sS --max-time 40 \
      "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getUpdates?offset=${OFFSET}&timeout=25&allowed_updates=%5B%22message%22%5D" 2>/dev/null) || {
        sleep 2
        continue
      }
    if ! echo "$RESP" | jq -e '.ok == true' >/dev/null 2>&1; then
      sleep 2
      continue
    fi
    COUNT=$(echo "$RESP" | jq '.result | length')
    if [[ "$COUNT" -eq 0 ]]; then
      continue
    fi
    # Iterate updates, advance offset, look for PIN match
    while IFS= read -r UPDATE; do
      UID=$(echo "$UPDATE" | jq '.update_id')
      echo "$((UID + 1))" > "$PAIRING_OFFSET_FILE"
      MSG_TEXT=$(echo "$UPDATE" | jq -r '.message.text // empty' | tr -d '[:space:]')
      if [[ "$MSG_TEXT" == "$PIN" ]]; then
        MATCHED_CHAT_ID=$(echo "$UPDATE" | jq -r '.message.chat.id')
        break 2
      fi
    done < <(echo "$RESP" | jq -c '.result[]')
  done

  rm -f "$PAIRING_OFFSET_FILE"

  if [[ -z "$MATCHED_CHAT_ID" ]]; then
    echo "❌ No PIN received within 5 minutes. Re-run /telegram setup." >&2
    exit 1
  fi

  set_env_key AUTHORIZED_CHAT_ID "$MATCHED_CHAT_ID"
  AUTHORIZED_CHAT_ID="$MATCHED_CHAT_ID"
  echo ""
  echo "✓ PIN received — chat $(mask "$AUTHORIZED_CHAT_ID") authorized"
fi

# ───────────────────────────────────────────────────────────
# Final summary
# ───────────────────────────────────────────────────────────
echo ""
echo "✅ forge-telegram configured"
echo "  Token:          $(mask "$TELEGRAM_BOT_TOKEN")"
echo "  Chat ID:        $(mask "$AUTHORIZED_CHAT_ID")"
if [[ -n "$OPENAI_API_KEY" ]]; then
  echo "  Voice (Whisper): enabled"
else
  echo "  Voice (Whisper): disabled (no OPENAI_API_KEY)"
fi
echo ""
echo "Run /telegram start to begin listening."
