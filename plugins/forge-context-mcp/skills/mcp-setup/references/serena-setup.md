# Serena Setup

LSP-powered code navigation for AI agents. Go-to-definition, find-references,
and symbol-level editing across 20+ languages via multilspy.

## What it does

- Wraps Language Server Protocol for AI agent consumption
- Go-to-definition, find-all-references, symbol search
- Always current — reads live language server, no stale index
- Works with Python, TypeScript, JavaScript, Java, Go, Rust, C/C++, C#, and more

## Install

### Prerequisites

```bash
# Requires Python 3.10+ and uv
pip install uv  # or: curl -LsSf https://astral.sh/uv/install.sh | sh
```

### Project-level configuration

Add to `.claude/settings.json`:

```json
{
  "mcpServers": {
    "serena": {
      "type": "stdio",
      "command": "uvx",
      "args": [
        "--from", "serena-mcp",
        "serena-mcp",
        "--workspace", "."
      ]
    }
  }
}
```

For multiple workspace roots (monorepo):

```json
{
  "mcpServers": {
    "serena": {
      "type": "stdio",
      "command": "uvx",
      "args": [
        "--from", "serena-mcp",
        "serena-mcp",
        "--workspace", "./apps/api",
        "--workspace", "./apps/web"
      ]
    }
  }
}
```

## Verify

Restart Claude Code. You should see Serena tools:
- `mcp__serena__go_to_definition` — jump to where a symbol is defined
- `mcp__serena__find_references` — find all usages of a symbol
- `mcp__serena__search_symbols` — search by symbol name
- `mcp__serena__get_diagnostics` — get language server diagnostics

## Usage

Claude uses Serena automatically when navigating code. No special prompting
needed — when Claude needs to understand how code connects, it will use
go-to-definition and find-references.

For explicit use:

```
Find all usages of the AuthService class
Where is handlePayment defined?
```

## Performance notes

- First query per language may be slow (language server startup)
- Subsequent queries are fast (server stays warm)
- Memory usage depends on project size and language server

## When to disable

For small projects where grep is sufficient. Serena's value increases with
codebase size and number of cross-file dependencies.

## Source

- Repo: https://github.com/nicobailon/serena
- Based on multilspy (Microsoft Research)
