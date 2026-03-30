#!/usr/bin/env bash
# Usage: bash commit.sh "feat: message" file1 file2 ...
# Pre-approved commit script for autonomous proactive-qa execution.
# Add to settings.json: Bash(bash ${CLAUDE_PLUGIN_ROOT}/scripts/commit.sh:*)
trap 'exit 0' ERR

MSG="$1"
shift

if [ $# -eq 0 ]; then
  echo "Error: no files specified"
  echo "Usage: bash commit.sh \"feat: message\" file1 file2 ..."
  exit 0
fi

git add "$@"
git commit -m "$MSG

Co-Authored-By: Claude <noreply@anthropic.com>"
