---
# Curated from: anthropics/claude-code (plugins/hookify) — Author: Daisy Hollman (Anthropic)
description: Get help with the hookify plugin
allowed-tools: ["Read"]
---

# Hookify Plugin Help

Explain how hookify works:

## How It Works

Hookify installs generic hooks on PreToolUse, PostToolUse, Stop, and UserPromptSubmit events. These hooks read `.claude/hookify.*.local.md` configuration files and check if any rules match the current operation.

## Rule Format

```markdown
---
name: warn-dangerous-rm
enabled: true
event: bash
pattern: rm\s+-rf
action: warn
---

Warning message shown when rule triggers.
```

## Commands

- **`/hookify [description]`** — Create rules from instructions or conversation analysis
- **`/hookify:list`** — List all configured rules
- **`/hookify:configure`** — Enable/disable rules interactively
- **`/hookify:help`** — This help

## Event Types

- `bash` — Bash commands
- `file` — Edit/Write/MultiEdit
- `stop` — When agent wants to stop
- `prompt` — User prompt submission
- `all` — All events

## Actions

- `warn` (default) — Show message, allow operation
- `block` — Prevent operation

## Key Points

- Rules take effect immediately — no restart needed
- Rules stored in `.claude/hookify.*.local.md` (gitignored)
- Python regex syntax for patterns
- Check `examples/` directory for sample rules
