---
# Curated from: anthropics/claude-code (plugins/plugin-dev) — Author: Daisy Hollman (Anthropic)
description: "Create a new Claude Code plugin with guided 8-phase workflow"
argument-hint: "[optional description of the plugin to create]"
---

# Create Plugin Workflow

Follow this 8-phase structured workflow to create a Claude Code plugin from scratch.

## Phase 1: Discovery

Understand the plugin's purpose:
- What problem does this plugin solve?
- Who will use it?
- What are the core use cases?

Ask clarifying questions. Do not proceed until purpose is clear.

## Phase 2: Component Planning

Determine which components are needed:
- **Skills** — Auto-activating knowledge and workflows
- **Commands** — User-invoked slash commands
- **Agents** — Autonomous subprocesses
- **Hooks** — Event-driven automation
- **MCP Servers** — External service integrations
- **Settings** — User-configurable options

Load the relevant skill for each component type selected.

## Phase 3: Detailed Design

For each component, resolve all ambiguities:
- Skill trigger phrases and content scope
- Command arguments and tool permissions
- Agent roles and triggering conditions
- Hook events and validation logic
- MCP server connections and auth

## Phase 4: Structure Creation

Create plugin directory structure and manifest:

```bash
mkdir -p plugin-name/.claude-plugin
mkdir -p plugin-name/{commands,agents,skills,hooks,scripts}
```

Create `.claude-plugin/plugin.json` with required metadata.

## Phase 5: Component Implementation

Implement each component following best practices:
- Skills: Third-person descriptions, lean SKILL.md, progressive disclosure
- Commands: Written FOR Claude, with argument-hint and allowed-tools
- Agents: Concrete triggering examples, focused system prompts
- Hooks: Use ${CLAUDE_PLUGIN_ROOT}, validate inputs, set timeouts

## Phase 6: Validation

Run validation checks:
- Use plugin-validator agent for comprehensive validation
- Use skill-reviewer agent for each skill
- Validate JSON files with `python3 -m json.tool`

## Phase 7: Testing

Test in Claude Code:
```bash
cc --plugin-dir /path/to/plugin-name
```

Verify:
- Skills trigger on expected phrases
- Commands execute correctly
- Agents activate appropriately
- Hooks fire on correct events

## Phase 8: Documentation

Prepare for distribution:
- Document all components and their purpose
- List required environment variables
- Provide installation instructions
- Note any dependencies

---

Use TodoWrite to track progress across all phases. Confirm with the user before advancing between phases.
