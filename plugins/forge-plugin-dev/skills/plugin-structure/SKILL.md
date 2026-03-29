---
# Curated from: anthropics/claude-code (plugins/plugin-dev) — Author: Daisy Hollman (Anthropic)
name: Plugin Structure
description: This skill should be used when the user wants to understand "plugin structure", "plugin.json manifest", "auto-discovery", "plugin directory layout", or needs guidance on how to organize Claude Code plugins, component placement, or manifest configuration.
version: 0.1.0
---

# Plugin Structure for Claude Code

Claude Code plugins follow a standardized directory structure with automatic component discovery.

## Directory Structure

```
plugin-name/
├── .claude-plugin/
│   └── plugin.json          # Required: Plugin manifest
├── commands/                 # Slash commands (.md files)
├── agents/                   # Subagent definitions (.md files)
├── skills/                   # Agent skills (subdirectories)
│   └── skill-name/
│       └── SKILL.md         # Required for each skill
├── hooks/
│   └── hooks.json           # Event handler configuration
├── .mcp.json                # MCP server definitions
└── scripts/                 # Helper scripts and utilities
```

**Critical rules:**
1. `plugin.json` MUST be in `.claude-plugin/` directory
2. Component directories MUST be at plugin root level, NOT nested inside `.claude-plugin/`
3. Only create directories for components the plugin actually uses
4. Use kebab-case for all directory and file names

## Plugin Manifest (plugin.json)

### Required Fields

```json
{
  "name": "plugin-name"
}
```

### Recommended Metadata

```json
{
  "name": "plugin-name",
  "version": "1.0.0",
  "description": "Brief explanation of plugin purpose",
  "author": { "name": "Author Name", "email": "author@example.com" },
  "repository": "https://github.com/user/plugin-name",
  "license": "MIT",
  "keywords": ["testing", "automation"]
}
```

## Auto-Discovery Mechanism

Claude Code automatically discovers and loads components:

1. Reads `.claude-plugin/plugin.json` when plugin enables
2. Scans `commands/` for `.md` files
3. Scans `agents/` for `.md` files
4. Scans `skills/` for subdirectories containing `SKILL.md`
5. Loads `hooks/hooks.json`
6. Loads `.mcp.json`

## Portable Path References

Always use `${CLAUDE_PLUGIN_ROOT}` for all intra-plugin path references.

**Never use:**
- Hardcoded absolute paths
- Relative paths from working directory
- Home directory shortcuts

## Common Patterns

### Minimal Plugin
```
my-plugin/
├── .claude-plugin/plugin.json
└── commands/hello.md
```

### Skill-Focused Plugin
```
my-plugin/
├── .claude-plugin/plugin.json
└── skills/
    ├── skill-one/SKILL.md
    └── skill-two/SKILL.md
```

### Full-Featured Plugin
```
my-plugin/
├── .claude-plugin/plugin.json
├── commands/
├── agents/
├── skills/
├── hooks/hooks.json
├── .mcp.json
└── scripts/
```
