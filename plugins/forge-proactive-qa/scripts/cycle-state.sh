#!/usr/bin/env bash
# Usage: bash cycle-state.sh [read|explore|autofix]
# Manages the cycle state file for /proactive-qa cycle mode.
#
# State file lives in project root (.proactive-qa-cycle), NOT in the plugin
# cache (~/.claude/plugins/...) — writing to ~/.claude/ triggers sensitive
# file permission prompts that break /loop automation.
#
# After /proactive-qa init, invoke via: bash .proactive-qa-scripts/cycle-state.sh [read|explore|autofix]
trap 'exit 0' ERR

STATE_FILE=".proactive-qa-cycle"

case "${1:-read}" in
  read)
    cat "$STATE_FILE" 2>/dev/null || echo "explore"
    ;;
  explore|autofix)
    echo "$1" > "$STATE_FILE"
    echo "Cycle state set to: $1"
    ;;
  *)
    echo "Usage: bash cycle-state.sh [read|explore|autofix]"
    ;;
esac
