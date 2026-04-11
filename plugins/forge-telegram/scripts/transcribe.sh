#!/usr/bin/env bash
# forge-telegram — Whisper transcription helper
# Usage: transcribe.sh <telegram_file_id>
#
# Invoked by listen.sh when a voice message arrives. Downloads the .ogg from
# Telegram, posts it to OpenAI Whisper API, prints the transcript to stdout.
#
# Exit codes (consumed by listen.sh):
#   0  success — transcript on stdout
#   1  generic error (network, API, empty file)
#   2  OPENAI_API_KEY not set — voice disabled
#   3  file larger than 25 MB (Whisper limit)

set -euo pipefail

FILE_ID="${1:?Usage: transcribe.sh <file_id>}"

# Honour the same TELEGRAM_STATE_DIR override as the rest of the plugin.
STATE_DIR="${TELEGRAM_STATE_DIR:-${HOME}/.claude/channels/telegram}"
ENV_FILE="${STATE_DIR}/.env"
INBOX_DIR="${STATE_DIR}/inbox"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "[transcribe] env file missing: $ENV_FILE" >&2
  exit 1
fi

TELEGRAM_BOT_TOKEN=$(grep -E '^TELEGRAM_BOT_TOKEN=' "$ENV_FILE" | head -1 | cut -d= -f2-)
OPENAI_API_KEY=$(grep -E '^OPENAI_API_KEY=' "$ENV_FILE" | head -1 | cut -d= -f2-)

if [[ -z "$TELEGRAM_BOT_TOKEN" ]]; then
  echo "[transcribe] missing TELEGRAM_BOT_TOKEN" >&2
  exit 1
fi

if [[ -z "$OPENAI_API_KEY" ]]; then
  # Voice disabled — distinct exit code so listen.sh can emit a specific message
  exit 2
fi

# Step 1: getFile to resolve file_path + size
GET_RESP=$(curl -sS --max-time 15 \
  "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getFile?file_id=${FILE_ID}" 2>/dev/null) || {
  echo "[transcribe] getFile request failed (network)" >&2
  exit 1
}

if ! echo "$GET_RESP" | jq -e '.ok == true' >/dev/null 2>&1; then
  SAFE=$(echo "$GET_RESP" | sed -E 's#bot[0-9]+:[A-Za-z0-9_-]+#bot<REDACTED>#g')
  echo "[transcribe] getFile error: $SAFE" >&2
  exit 1
fi

FILE_PATH=$(echo "$GET_RESP" | jq -r '.result.file_path')
FILE_SIZE=$(echo "$GET_RESP" | jq -r '.result.file_size // 0')

if [[ -z "$FILE_PATH" || "$FILE_PATH" == "null" ]]; then
  echo "[transcribe] no file_path in response" >&2
  exit 1
fi

# Whisper limit: 25 MB
if (( FILE_SIZE > 25 * 1024 * 1024 )); then
  exit 3
fi

# Step 2: download the voice file.
#
# IMPORTANT: write inside $INBOX_DIR rather than the system $TMPDIR. On macOS
# TMPDIR defaults to /var/folders/... which is outside the plugin's state dir
# and therefore outside whatever the user added to sandbox.filesystem.allowWrite.
# $INBOX_DIR is already on that allowlist (it's the same dir where inbound
# photos land), so a temp file here costs us nothing extra in terms of
# sandbox permissions.
mkdir -p "$INBOX_DIR"
TMPFILE=$(mktemp "${INBOX_DIR}/voice-XXXXXX") || {
  echo "[transcribe] mktemp failed (target: $INBOX_DIR)" >&2
  exit 1
}
# Rename with .ogg extension so Whisper detects format
mv "$TMPFILE" "${TMPFILE}.ogg"
TMPFILE="${TMPFILE}.ogg"
trap 'rm -f "$TMPFILE"' EXIT

if ! curl -sS --max-time 60 -o "$TMPFILE" \
     "https://api.telegram.org/file/bot${TELEGRAM_BOT_TOKEN}/${FILE_PATH}" 2>/dev/null; then
  echo "[transcribe] download failed" >&2
  exit 1
fi

if [[ ! -s "$TMPFILE" ]]; then
  echo "[transcribe] empty voice file" >&2
  exit 1
fi

# Step 3: Whisper API
WRESP=$(curl -sS --max-time 120 \
  https://api.openai.com/v1/audio/transcriptions \
  -H "Authorization: Bearer ${OPENAI_API_KEY}" \
  -F "file=@${TMPFILE}" \
  -F "model=whisper-1" \
  -F "response_format=json" 2>/dev/null) || {
  echo "[transcribe] Whisper request failed (network)" >&2
  exit 1
}

if ! echo "$WRESP" | jq -e '.text' >/dev/null 2>&1; then
  # Redact any leaked keys in the error
  SAFE=$(echo "$WRESP" | sed -E 's#sk-[A-Za-z0-9_-]+#sk-<REDACTED>#g')
  echo "[transcribe] Whisper error: $SAFE" >&2
  exit 1
fi

echo "$WRESP" | jq -r '.text'
