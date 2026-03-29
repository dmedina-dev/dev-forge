---
# Curated from: anthropics/claude-code (plugins/commit-commands) — Author: Anthropic
description: Cleans up all git branches marked as [gone] (branches deleted on remote but still exist locally), including removing associated worktrees.
---

## Your Task

Execute the following bash commands to clean up stale local branches.

## Commands to Execute

1. **List branches to identify any with [gone] status**
   ```bash
   git branch -v
   ```

   Note: Branches with a '+' prefix have associated worktrees.

2. **Identify worktrees that need to be removed**
   ```bash
   git worktree list
   ```

3. **Remove worktrees and delete [gone] branches**
   ```bash
   git branch -v | grep '\[gone\]' | sed 's/^[+* ]//' | awk '{print $1}' | while read branch; do
     echo "Processing branch: $branch"
     worktree=$(git worktree list | grep "\\[$branch\\]" | awk '{print $1}')
     if [ ! -z "$worktree" ] && [ "$worktree" != "$(git rev-parse --show-toplevel)" ]; then
       echo "  Removing worktree: $worktree"
       git worktree remove --force "$worktree"
     fi
     echo "  Deleting branch: $branch"
     git branch -D "$branch"
   done
   ```

If no branches are marked as [gone], report that no cleanup was needed.
