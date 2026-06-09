---
name: forge-profiles
description: >
  Plugin profile manager — switch between sets of active plugins per work mode. Use when the
  user mentions "switch profile", "change work mode", "activate dev plugins", "reduce context",
  "too many plugins", "plugin profile", "work mode", or wants to manage which plugins are active
  for different tasks. Also use when the user says "I'm going to work on X now" and X implies a
  different plugin set. Manages ALL plugins (forge, external, any marketplace), not just forge plugins.
---

# Plugin Profile Manager

Manage plugin profiles to switch between work modes quickly. Each profile defines which plugins
are active — switching profiles installs the right ones and removes the rest, reducing context
to only what's relevant.

## Why Profiles

Claude Code loads every installed plugin into context. More plugins = more tokens consumed before
you even start working. Profiles let you:
- Keep a lean "daily driver" set for regular coding
- Switch to a heavy "plugin-dev" set only when creating plugins
- Have a "review" set with just the analysis tools
- Any combination you need

## How It Works

Profiles are stored inside `.claude/settings.local.json` under `pluginConfigs["forge-profiles@dev-forge"].options.profiles`.
This uses the official `pluginConfigs` schema key, keeping profile data valid and organized under the plugin namespace.
The file is automatically gitignored by Claude Code, so profiles stay personal and project-local.

When you switch profiles, the command:
1. Reads `.claude/settings.local.json`
2. Loads the target profile from `pluginConfigs["forge-profiles@dev-forge"].options.profiles`
3. Calculates what plugins and MCP servers to add/remove
4. Updates `enabledPlugins` in `.claude/settings.local.json` (sets the target profile's plugins to
   `true`, sets the ones being deactivated to `false` or removes them) and replaces the
   `mcpServers` object in `.mcp.json` (preserves permissions, env, everything else)
5. Tells you to run `/reload-plugins` to apply

## Commands

- `/profile-create` — create a new profile via interview (starts from current config)
- `/profile-list` — show all profiles with descriptions
- `/profile-change [name]` — switch to a profile (shows diff first)

## Storage

Everything lives in `.claude/settings.local.json` under the `pluginConfigs` key:

```json
{
  "enabledPlugins": {
    "forge-keeper@dev-forge": true,
    "forge-superpowers@dev-forge": true
  },
  "permissions": { "...existing permissions..." },
  "pluginConfigs": {
    "forge-profiles@dev-forge": {
      "options": {
        "profiles": {
          "daily": {
            "description": "Everyday coding — keeper, superpowers, commit, security",
            "plugins": ["forge-keeper@dev-forge", "forge-commit@dev-forge"],
            "mcpServers": {
              "context7": { "type": "stdio", "command": "npx", "args": ["..."] }
            },
            "created_at": "2026-04-04"
          },
          "plugin-dev": {
            "description": "Plugin development with skill-creator and forge-plugin-dev",
            "plugins": ["skill-creator@claude-plugins-official"],
            "mcpServers": {},
            "created_at": "2026-04-04"
          }
        }
      }
    }
  }
}
```

MCP servers are not part of settings.local.json — project MCP servers live in `.mcp.json` at the
project root (top-level `mcpServers` object), which profiles also manage.

Each profile stores the exact plugin identifiers (`plugin@marketplace` format) and the full
`mcpServers` object. This ensures profiles work regardless of how plugins were installed or how
MCP servers were configured (stdio, SSE, HTTP).

No extra files or directories needed. Profile data lives under the official `pluginConfigs`
schema key, properly namespaced to the plugin.
