---
# Curated from: anthropics/claude-code (plugins/hookify) — Author: Daisy Hollman (Anthropic)
description: Enable or disable hookify rules interactively
allowed-tools: ["Glob", "Read", "Edit", "AskUserQuestion", "Skill"]
---

# Configure Hookify Rules

**Load hookify:writing-rules skill first** to understand rule format.

1. Find all `.claude/hookify.*.local.md` files
2. Read each, extract name and enabled state
3. Use AskUserQuestion (multiSelect) to let user toggle rules
4. Edit selected files: `enabled: true` ↔ `enabled: false`
5. Confirm changes — they take effect immediately

If no rules found, suggest using `/hookify` to create rules first.
