---
# Curated from: anthropics/claude-code (plugins/plugin-dev) — Author: Daisy Hollman (Anthropic)
name: Command Development
description: This skill should be used when the user wants to "create a slash command", "command frontmatter", "define command arguments", "write a command", or needs guidance on command structure, YAML frontmatter fields, dynamic arguments, or command development for Claude Code plugins.
version: 0.1.0
---

# Command Development for Claude Code Plugins

Slash commands are Markdown files containing prompts that Claude executes during interactive sessions. They enable reusable, consistent workflows.

## Core Principle

**Commands are instructions FOR Claude, not TO users.** When invoking `/command-name`, the command content becomes Claude's directives. Write commands as actionable guidance.

## File Structure & Location

Commands are `.md` files stored in:
- **Project commands**: `.claude/commands/` (team-shared)
- **Personal commands**: `~/.claude/commands/` (all projects)
- **Plugin commands**: `plugin-name/commands/` (plugin-specific)

## Key Frontmatter Fields

| Field | Purpose | Example |
|-------|---------|---------|
| `description` | Brief help text | "Review code for security issues" |
| `allowed-tools` | Tool access restrictions | "Read, Write, Bash(git:*)" |
| `model` | Specify Claude model | "haiku", "sonnet", "opus" |
| `argument-hint` | Document expected arguments | "[pr-number] [priority]" |

## Dynamic Arguments

**All arguments as string:**
```markdown
Fix issue #$ARGUMENTS following standards.
```

**Positional arguments:**
```markdown
Review PR #$1 with priority $2, assign to $3.
```

## File References

Include file contents using `@` syntax:
```markdown
Review @$1 for code quality and potential bugs.
```

## Bash Execution

Execute bash commands inline:
```markdown
Files changed: !`git diff --name-only`
```

## Plugin Integration

Plugin commands can access `${CLAUDE_PLUGIN_ROOT}`:
```markdown
Run: !`node ${CLAUDE_PLUGIN_ROOT}/scripts/analyze.js`
```

## Best Practices

1. **Single responsibility** — One command, one task
2. **Explicit dependencies** — Use `allowed-tools` when needed
3. **Document arguments** — Always provide `argument-hint`
4. **Safe bash execution** — Restrict with patterns like `Bash(git:*)`
5. **Clear descriptions** — Self-explanatory in `/help`
6. **Consistent naming** — Use verb-noun pattern (review-pr, fix-issue)
