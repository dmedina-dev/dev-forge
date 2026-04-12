#!/usr/bin/env bash
# forge-telegram — manage Telegram bot menu commands
# Usage: bash menu.sh <get|set|reset|register>
#
# Subcommands:
#   get                Show the saved custom menu (or "defaults" if none)
#   set <file.json>    Save a custom menu from a JSON file and register it
#   set -              Read JSON from stdin
#   reset              Remove custom menu, re-register defaults
#   register           Register the saved menu (or defaults) with Telegram API
#
# Menu JSON format — array of {command, description} objects:
#   [
#     {"command": "qa",    "description": "Run lint + test + build"},
#     {"command": "tests", "description": "Run full test suite"}
#   ]
#
# The custom menu is stored at ~/.claude/channels/telegram/menu.json.
# setup.sh and start both call "menu.sh register" so the correct menu
# is always active — custom menus survive setup re-runs.
#
# Built-in commands (/stop, /qa, /status) are ALWAYS appended to the
# registered menu. They cannot be removed or overridden by custom menus.
# The assistant executes them from Telegram regardless of response mode.

set -euo pipefail

STATE_DIR="${TELEGRAM_STATE_DIR:-${HOME}/.claude/channels/telegram}"
ENV_FILE="${STATE_DIR}/.env"
MENU_FILE="${STATE_DIR}/menu.json"

# Read a single key from env file
get_env_key() {
  { grep -E "^$1=" "$ENV_FILE" 2>/dev/null || true; } | head -1 | cut -d= -f2-
}

# Built-in commands — always registered, always authorized from Telegram
# regardless of mode. These override any custom menu entry with the same name.
BUILTIN_NAMES='["stop","qa","status"]'
builtin_commands() {
  jq -nc '[
    {command: "stop",   description: "Stop the listener"},
    {command: "qa",     description: "Validate project state (lint + test + build)"},
    {command: "status", description: "Report current task and activity"}
  ]'
}

# Merge custom (or empty) commands with built-ins.
# Removes any custom entry whose name collides with a built-in.
merge_with_builtins() {
  local custom="$1"
  local builtins
  builtins=$(builtin_commands)
  echo "$custom" | jq --argjson builtins "$builtins" --argjson names "$BUILTIN_NAMES" \
    '[.[] | select(.command as $c | $names | index($c) | not)] + $builtins'
}

# Register commands with Telegram API at both default and all_private_chats
# scopes. The all_private_chats scope takes precedence in DM conversations,
# so we must write there too — otherwise stale commands from BotFather or
# other tools will shadow ours.
register_commands() {
  local commands="$1"
  local token
  token=$(get_env_key TELEGRAM_BOT_TOKEN)
  if [[ -z "$token" ]]; then
    echo "No TELEGRAM_BOT_TOKEN — skipping menu registration" >&2
    return 1
  fi
  local url="https://api.telegram.org/bot${token}/setMyCommands"
  local body="{\"commands\": ${commands}}"
  local body_private="{\"commands\": ${commands}, \"scope\": {\"type\": \"all_private_chats\"}}"
  local resp failed=0
  for payload in "$body" "$body_private"; do
    resp=$(curl -sS --max-time 10 -X POST "$url" \
      -H "Content-Type: application/json" \
      -d "$payload" 2>&1)
    if ! echo "$resp" | jq -e '.ok == true' >/dev/null 2>&1; then
      echo "setMyCommands failed: ${resp}" >&2
      failed=1
    fi
  done
  return $failed
}

# Format commands for display
display_commands() {
  local commands="$1"
  echo "$commands" | jq -r '.[] | "  /\(.command) — \(.description)"'
}

# ─────────────────────────────────────────────────
# Subcommands
# ─────────────────────────────────────────────────

cmd_get() {
  if [[ -f "$MENU_FILE" ]]; then
    echo "Custom menu + built-ins:"
    display_commands "$(merge_with_builtins "$(cat "$MENU_FILE")")"
  else
    echo "Built-in commands only (no custom menu):"
    display_commands "$(builtin_commands)"
  fi
}

cmd_set() {
  local source="${1:-}"
  local json

  if [[ "$source" == "-" ]]; then
    json=$(cat)
  elif [[ -n "$source" && -f "$source" ]]; then
    json=$(cat "$source")
  else
    echo "Usage: menu.sh set <file.json>  or  menu.sh set -" >&2
    exit 1
  fi

  # Validate: must be a JSON array of objects with command + description
  if ! echo "$json" | jq -e 'type == "array" and all(has("command") and has("description"))' >/dev/null 2>&1; then
    echo "Invalid menu JSON — must be an array of {command, description} objects" >&2
    exit 1
  fi

  mkdir -p "$STATE_DIR"
  printf '%s\n' "$json" > "$MENU_FILE"

  local merged
  merged=$(merge_with_builtins "$json")
  register_commands "$merged"

  local custom_count
  custom_count=$(echo "$json" | jq 'length')
  echo "Menu saved and registered (${custom_count} custom + 3 built-in):"
  display_commands "$merged"
}

cmd_reset() {
  rm -f "$MENU_FILE"
  local builtins
  builtins=$(builtin_commands)
  register_commands "$builtins"
  echo "Custom menu removed — built-ins only:"
  display_commands "$builtins"
}

cmd_register() {
  local commands
  if [[ -f "$MENU_FILE" ]]; then
    commands=$(merge_with_builtins "$(cat "$MENU_FILE")")
  else
    commands=$(builtin_commands)
  fi
  register_commands "$commands"
}

# ─────────────────────────────────────────────────
# Dispatch
# ─────────────────────────────────────────────────

case "${1:-}" in
  get)      cmd_get ;;
  set)      cmd_set "${2:-}" ;;
  reset)    cmd_reset ;;
  register) cmd_register ;;
  *)
    echo "Usage: menu.sh <get|set|reset|register>" >&2
    echo "" >&2
    echo "  get                Show saved menu (or defaults)" >&2
    echo "  set <file.json>    Save + register a custom menu" >&2
    echo "  set -              Read menu JSON from stdin" >&2
    echo "  reset              Remove custom menu, restore defaults" >&2
    echo "  register           Re-register saved menu (or defaults) with Telegram" >&2
    exit 1
    ;;
esac
