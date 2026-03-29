---
# Curated from: anthropics/claude-code (plugins/plugin-dev) — Author: Daisy Hollman (Anthropic)
name: MCP Integration
description: This skill should be used when the user wants to "add MCP server", "configure .mcp.json", "Model Context Protocol", "connect external service", or needs guidance on MCP server types (stdio, SSE, HTTP, WebSocket), authentication patterns, or MCP integration for Claude Code plugins.
version: 0.1.0
---

# MCP Integration for Claude Code Plugins

Model Context Protocol (MCP) enables Claude Code plugins to integrate external services and APIs by exposing them as structured tools.

## Configuration Methods

### Method 1: Dedicated .mcp.json (Recommended)

Place at plugin root for clear separation:

```json
{
  "mcpServers": {
    "server-name": {
      "command": "node",
      "args": ["${CLAUDE_PLUGIN_ROOT}/servers/server.js"],
      "env": {
        "API_KEY": "${API_KEY}"
      }
    }
  }
}
```

### Method 2: Inline in plugin.json

Add `mcpServers` field directly for simpler setups.

## Server Types

| Type | Use Case | Example |
|------|----------|---------|
| **stdio** | Local process execution | Custom servers |
| **SSE** | Cloud services with OAuth | External APIs |
| **HTTP** | REST API connections | Token-based auth |
| **WebSocket** | Real-time bidirectional | Live data feeds |

## Key Implementation Points

- Use `${CLAUDE_PLUGIN_ROOT}` for portable file paths
- Environment variables support substitution in configurations
- Tools are automatically prefixed with `mcp__plugin_<name>__`
- Pre-allow specific tools in command frontmatter for security
- MCP servers launch automatically when plugins enable

## Security Practices

- Always use secure connections (HTTPS)
- Use environment variables for tokens, never hardcode credentials
- Scope permissions by pre-allowing only necessary tools
- Document required environment variables for users

## Testing & Debugging

- Use `/mcp` command to verify server connections
- Run `claude --debug` for troubleshooting
- Test server independently before plugin integration
