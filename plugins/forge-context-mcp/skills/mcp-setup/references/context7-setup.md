# Context7 Setup

Up-to-date, version-specific library documentation for AI coding agents.
51K+ stars. Eliminates hallucinations from stale training data.

## What it does

- Fetches current documentation for any library on demand
- Vector search + custom reranking for relevant sections
- 65% token reduction vs full docs, 38% latency reduction
- Add "use context7" to prompts when working with unfamiliar APIs

## Install

### Option A: Project-level (recommended)

Add to `.claude/settings.json` in the project root:

```json
{
  "mcpServers": {
    "context7": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"]
    }
  }
}
```

### Option B: Global (all projects)

Add to `~/.claude/settings.json`:

```json
{
  "mcpServers": {
    "context7": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"]
    }
  }
}
```

## Verify

Restart Claude Code. You should see Context7 tools available:
- `mcp__context7__resolve-library-id` — find a library's Context7 ID
- `mcp__context7__get-library-docs` — fetch documentation

## Usage

Just add "use context7" to your prompt:

```
Implement OAuth2 with passport.js, use context7
```

Claude will automatically fetch current passport.js docs before coding.

## When to disable

If you're not using external libraries (pure internal code), disable to save
context window space. Remove from settings.json or comment out.

## Source

- Repo: https://github.com/nicobailon/context7
- PulseMCP: ranked #3 globally
