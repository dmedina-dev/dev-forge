# XRAY Setup

Lightweight, on-demand code intelligence via ast-grep. No persistent index.
Each query runs fresh against current code.

## What it does

- Structural code analysis using ast-grep patterns
- "Map, Find, Impact" progressive discovery pattern:
  1. **Map** — overview of project structure and symbols
  2. **Find** — locate specific patterns, usages, implementations
  3. **Impact** — trace what would break if you change something
- No index to build or maintain — always current
- Supports all languages ast-grep supports (JS/TS, Python, Go, Rust, Java, C/C++, etc.)

## Install

### Prerequisites

```bash
# Requires ast-grep CLI
npm install -g @ast-grep/cli
# or: cargo install ast-grep
# or: brew install ast-grep
```

### Project-level configuration

Add to `.claude/settings.json`:

```json
{
  "mcpServers": {
    "xray": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "xray-mcp@latest"]
    }
  }
}
```

## Verify

Restart Claude Code. You should see XRAY tools:
- `mcp__xray__map` — get project structure overview
- `mcp__xray__find` — find code patterns using ast-grep
- `mcp__xray__impact` — analyze impact of changes

## Usage

Claude uses XRAY when it needs structural understanding:

```
What would break if I rename the handleAuth function?
Find all React components that use useState without useEffect
Map the architecture of the payments module
```

## Pattern examples

XRAY uses ast-grep patterns (tree-sitter based):

```
# Find all async functions that don't have try/catch
async function $NAME($$$) { $$$ }

# Find all React components with props destructuring
function $NAME({ $$$ }) { return $$$ }

# Find all imports from a specific package
import { $$$ } from "express"
```

## When to disable

For small projects where grep is sufficient. XRAY shines when you need
structural queries ("find all functions that call X but don't handle errors")
that text search can't express.

## Source

- Repo: https://github.com/nicobailon/xray-mcp
- Built on ast-grep (tree-sitter)
