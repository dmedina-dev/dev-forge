---
# Curated from: anthropics/claude-code (plugins/plugin-dev) — Author: Daisy Hollman (Anthropic)
name: Hook Development
description: This skill should be used when the user wants to "create a hook", "add a PreToolUse hook", "validate tool use", "implement prompt-based hooks", or mentions hook events (PreToolUse, PostToolUse, Stop, SessionStart, UserPromptSubmit), or needs guidance on hook development for Claude Code plugins.
version: 0.1.0
---

# Hook Development for Claude Code Plugins

Hooks are event-driven automation scripts that execute in response to Claude Code events. Use hooks to validate operations, enforce policies, add context, and integrate external tools.

## Hook Types

### Prompt-Based Hooks (Recommended)

LLM-driven decision making for context-aware validation:

```json
{
  "type": "prompt",
  "prompt": "Evaluate if this tool use is appropriate: $TOOL_INPUT",
  "timeout": 30
}
```

### Command Hooks

Execute bash commands for deterministic checks:

```json
{
  "type": "command",
  "command": "bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate.sh",
  "timeout": 60
}
```

## Plugin hooks.json Format

```json
{
  "description": "Brief explanation of hooks",
  "hooks": {
    "PreToolUse": [...],
    "Stop": [...],
    "SessionStart": [...]
  }
}
```

## Hook Events

| Event | When | Use For |
|-------|------|---------|
| PreToolUse | Before tool | Validation, modification |
| PostToolUse | After tool | Feedback, logging |
| UserPromptSubmit | User input | Context, validation |
| Stop | Agent stopping | Completeness check |
| SubagentStop | Subagent done | Task validation |
| SessionStart | Session begins | Context loading |
| SessionEnd | Session ends | Cleanup, logging |
| PreCompact | Before compact | Preserve context |

## Matchers

```json
"matcher": "Write"          // Exact match
"matcher": "Read|Write|Edit" // Multiple tools
"matcher": "*"              // All tools
"matcher": "mcp__.*"        // Regex pattern
```

## Hook Output Format

```json
{
  "continue": true,
  "suppressOutput": false,
  "systemMessage": "Message for Claude"
}
```

**PreToolUse specific:**
```json
{
  "hookSpecificOutput": {
    "permissionDecision": "allow|deny|ask",
    "updatedInput": {"field": "modified_value"}
  }
}
```

## Environment Variables

- `$CLAUDE_PROJECT_DIR` — Project root path
- `$CLAUDE_PLUGIN_ROOT` — Plugin directory (always use for portability)
- `$CLAUDE_ENV_FILE` — SessionStart only: persist env vars

## Security Best Practices

- Validate all inputs in command hooks
- Check for path traversal and sensitive files
- Quote all bash variables
- Set appropriate timeouts
- Use `set -euo pipefail` in scripts

## Important: Hooks Load at Session Start

Changes to hook configuration require restarting Claude Code. Use `claude --debug` for hook debugging.

## Additional Resources

For detailed patterns and advanced techniques, consult:
- **`references/patterns.md`** — Common hook patterns
- **`references/migration.md`** — Migrating from basic to advanced hooks
- **`references/advanced.md`** — Advanced use cases
