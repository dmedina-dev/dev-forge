#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="/tmp/session-keeper"
STATE_FILE="$STATE_DIR/state.json"
MIN_FILES="${SK_MIN_FILES:-20}"
MIN_ZONES="${SK_MIN_ZONES:-3}"
COOLDOWN="${SK_COOLDOWN:-15}"

mkdir -p "$STATE_DIR"

# Gather session activity
CHANGED_FILES=$(git diff --name-only HEAD 2>/dev/null || true)
STAGED_FILES=$(git diff --name-only --cached 2>/dev/null || true)
ALL_FILES=$(printf '%s\n%s' "$CHANGED_FILES" "$STAGED_FILES" | sort -u | grep -v '^$' || true)
FILE_COUNT=$(echo "$ALL_FILES" | grep -c '.' 2>/dev/null || true)
[ -z "$FILE_COUNT" ] && FILE_COUNT=0

ZONES=$(echo "$ALL_FILES" | cut -d'/' -f1 | sort -u | grep -v '^$' || true)
ZONE_COUNT=$(echo "$ZONES" | grep -c '.' 2>/dev/null || true)
[ -z "$ZONE_COUNT" ] && ZONE_COUNT=0

# Load state
PROMPT_COUNT=1; LAST_REMINDER=0; LAST_FILE_COUNT=0
if [ -f "$STATE_FILE" ]; then
  PROMPT_COUNT=$(( $(grep -o '"prompt_count":[0-9]*' "$STATE_FILE" | grep -o '[0-9]*') + 1 ))
  LAST_REMINDER=$(grep -o '"last_reminder":[0-9]*' "$STATE_FILE" | grep -o '[0-9]*' || echo 0)
  LAST_FILE_COUNT=$(grep -o '"last_file_count":[0-9]*' "$STATE_FILE" | grep -o '[0-9]*' || echo 0)
fi

SINCE_LAST=$(( PROMPT_COUNT - LAST_REMINDER ))
NEW_ACTIVITY=$(( FILE_COUNT - LAST_FILE_COUNT ))
[ "$NEW_ACTIVITY" -lt 0 ] && NEW_ACTIVITY=0

# Decide
SHOULD_REMIND=false
if [ "$FILE_COUNT" -ge "$MIN_FILES" ] && [ "$ZONE_COUNT" -ge "$MIN_ZONES" ] && \
   [ "$SINCE_LAST" -ge "$COOLDOWN" ] && [ "$NEW_ACTIVITY" -gt 0 ]; then
  SHOULD_REMIND=true
fi

# Zone detail
ZONE_DETAIL=""
if [ "$SHOULD_REMIND" = true ]; then
  while IFS= read -r zone; do
    [ -z "$zone" ] && continue
    count=$(echo "$ALL_FILES" | grep -c "^${zone}/" 2>/dev/null || true)
    [ -z "$count" ] && count=0
    ZONE_DETAIL="${ZONE_DETAIL}  - ${zone}/ (${count} files)\n"
  done <<< "$ZONES"
fi

# Save state
RV=$LAST_REMINDER; [ "$SHOULD_REMIND" = true ] && RV=$PROMPT_COUNT
cat > "$STATE_FILE" << STATEJSON
{"prompt_count":$PROMPT_COUNT,"last_reminder":$RV,"last_file_count":$FILE_COUNT,"zone_count":$ZONE_COUNT}
STATEJSON

# Emit
if [ "$SHOULD_REMIND" = true ]; then
  cat << EOF
{"message":"Context checkpoint — ${FILE_COUNT} files changed across ${ZONE_COUNT} zones:\n$(echo -e "$ZONE_DETAIL")\nConsider running /session-keeper:sync to capture these changes. (Ignore if you're in the middle of something.)"}
EOF
fi
