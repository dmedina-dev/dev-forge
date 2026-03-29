---
# Curated from: anthropics/claude-code (plugins/plugin-dev) — Author: Daisy Hollman (Anthropic)
name: Agent Development
description: This skill should be used when the user wants to "create an agent", "write a subagent", "autonomous agent", "agent frontmatter", "agent description", or needs guidance on agent structure, system prompt design, or agent development best practices for Claude Code plugins.
version: 0.1.0
---

# Agent Development for Claude Code Plugins

Agents function as autonomous subprocesses handling complex, multi-step tasks independently. They differ fundamentally from commands — agents operate autonomously while commands require user initiation.

## Essential Structure

Agents use markdown format with YAML frontmatter:

```
agents/
└── agent-name.md
    ├── YAML frontmatter (required)
    │   ├── name: identifier (3-50 chars, lowercase with hyphens)
    │   ├── description: triggering conditions with 2-4 examples
    │   ├── model: usually "inherit"
    │   └── color: visual identifier (blue, cyan, green, yellow, magenta, red)
    └── System prompt body (second-person instructions)
```

## Writing Descriptions

The description field is critical for agent triggering. Include:

1. Clear triggering conditions ("Use this agent when...")
2. Multiple example blocks showing different usage scenarios
3. Commentary explaining why each example warrants agent activation

**Example:**
```yaml
description: |
  Use this agent when a major project step has been completed and needs review.
  Examples:
  <example>
  Context: User completed implementing auth system
  user: "I've finished the auth implementation"
  assistant: "Let me use the code-reviewer agent to review against our plan"
  </example>
```

## System Prompt Design

Write in second person addressing the agent directly. Include:

- Role and specialization
- Numbered core responsibilities
- Step-by-step analysis process
- Quality standards
- Defined output format
- Edge case handling

Keep system prompts between 500-3,000 characters for optimal performance.

## Best Practices

**DO:**
- Include concrete triggering examples in description
- Use `inherit` model by default
- Restrict tools using least-privilege principle
- Test agent triggering with real scenarios

**DON'T:**
- Use generic descriptions
- Skip triggering conditions
- Give all agents identical colors
- Write vague system prompts
