---
name: mcp-setup
description: >
  Guide for configuring recommended MCP servers for codebase intelligence.
  Activates when user mentions "mcp server", "context7", "serena", "xray",
  "code intelligence", "codebase search", "library docs", or "set up MCP".
  Install this plugin when needed, uninstall after configuring.
---

# MCP Server Setup Guide

Configure MCP servers that enhance Claude Code's codebase understanding.
These are **external tools** — not plugins. They run as background processes
and provide Claude with structured code intelligence.

## Recommended servers

| Server | Purpose | Best for |
|--------|---------|----------|
| **Context7** | Up-to-date library documentation | Avoiding hallucinations about APIs |
| **Serena** | LSP-powered code navigation | Go-to-definition, find-references, symbol search |
| **XRAY** | Structural code analysis via ast-grep | Pattern matching, impact analysis, no index needed |

## Quick setup

### Context7 — Library documentation

Eliminates hallucinated API calls. Fetches current, version-specific docs.
Add "use context7" to prompts when working with libraries.

See `references/context7-setup.md` for installation steps.

### Serena — Code navigation

Wraps Language Server Protocol. Gives Claude go-to-definition, find-all-references,
and symbol-level editing across 20+ languages. Always current — no indexing.

See `references/serena-setup.md` for installation steps.

### XRAY — Structural analysis

Uses ast-grep for on-demand code intelligence. No persistent index. "Map, Find, Impact"
progressive discovery pattern. Good for large codebases.

See `references/xray-setup.md` for installation steps.

## Which to install

**Small project, using popular libraries** → Context7 only
**Medium project, multiple languages** → Context7 + Serena
**Large codebase, structural queries** → Context7 + Serena + XRAY

## After configuring

Uninstall this plugin — the MCP servers run independently from `.claude/settings.json`.
This plugin only provides setup guidance.

```
/plugin → Manage and uninstall plugins → forge-context-mcp → Uninstall
```
