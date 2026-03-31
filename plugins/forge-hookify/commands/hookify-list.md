---
# Curated from: anthropics/claude-code (plugins/hookify) — Author: Daisy Hollman (Anthropic)
description: List all configured hookify rules
allowed-tools: ["Glob", "Read", "Skill"]
---

# List Hookify Rules

**Load hookify:writing-rules skill first** to understand rule format.

1. Use Glob to find all `.claude/hookify.*.local.md` files
2. Read each file, extract frontmatter: name, enabled, event, pattern
3. Present results in a table:

```
| Name | Enabled | Event | Pattern | File |
|------|---------|-------|---------|------|
| warn-dangerous-rm | Yes | bash | rm\s+-rf | hookify.dangerous-rm.local.md |
```

4. For each rule, show brief preview with status
5. Add footer with management tips (edit, disable, delete, create)

If no rules found, suggest using `/hookify` to create the first rule.
