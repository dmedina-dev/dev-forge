---
# Curated from: anthropics/claude-code (plugins/hookify) — Author: Daisy Hollman (Anthropic)
name: Writing Hookify Rules
description: Use when creating or editing hookify rules. Provides rule file format, pattern syntax, event types, operators, and field reference.
---

# Writing Hookify Rules

## Rule File Format

```markdown
---
name: rule-identifier
enabled: true
event: bash|file|stop|prompt|all
pattern: regex-pattern-here
action: warn|block
---

Message shown when rule triggers.
```

## Frontmatter Fields

- **name** (required): kebab-case identifier (e.g. `warn-dangerous-rm`)
- **enabled** (required): `true` or `false`
- **event** (required): `bash`, `file`, `stop`, `prompt`, or `all`
- **action** (optional): `warn` (default, allows operation) or `block` (prevents operation)
- **pattern** (simple format): Regex to match against command (bash) or new_text (file)

## Advanced: Multiple Conditions

```yaml
conditions:
  - field: file_path
    operator: regex_match
    pattern: \.env$
  - field: new_text
    operator: contains
    pattern: API_KEY
```

All conditions must match.

## Operators

| Operator | Description |
|----------|-------------|
| `regex_match` | Regex pattern matching |
| `contains` | Substring check |
| `equals` | Exact match |
| `not_contains` | Must NOT contain |
| `starts_with` | Prefix check |
| `ends_with` | Suffix check |

## Fields by Event

| Event | Fields |
|-------|--------|
| bash | `command` |
| file | `file_path`, `new_text`, `old_text`, `content` |
| prompt | `user_prompt` |
| stop | `transcript`, `reason` |

## Pattern Examples

```
rm\s+-rf           → rm -rf commands
console\.log\(     → console.log() calls
(eval|exec)\(      → eval() or exec()
\.env$             → files ending in .env
chmod\s+777        → chmod 777
API_KEY\s*=        → API_KEY assignments
```

## File Location

Create in project's `.claude/` directory: `.claude/hookify.{name}.local.md`

Rules take effect immediately — no restart needed.
