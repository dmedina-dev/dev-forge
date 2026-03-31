#!/usr/bin/env bash
# Usage: bash commit.sh "feat: message" file1 file2 ...
# Pre-approved commit script for autonomous proactive-qa execution.
# After /proactive-qa init, invoke via: bash .proactive-qa-scripts/commit.sh "msg" files...
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
