---
description: "List all plugin profiles with descriptions and plugin counts"
---

# List Plugin Profiles

Show all available profiles and indicate which one matches the current configuration.

## Process

### Step 1: Read Profiles

1. Read `.claude/settings.local.json`
2. Navigate to `pluginConfigs["forge-profiles@dev-forge"].options.profiles`
3. If the file doesn't exist or the path doesn't exist: inform user "No profiles found. Create one with `/profile-create`." and stop
4. Parse each profile: name (the key), description, plugins array, mcpServers object, created_at

### Step 2: Detect Active Profile

1. Get the current `plugins` array and `mcpServers` object from settings.local.json
2. Compare current state against each profile (both plugins AND mcpServers must match)
3. Exact match (same plugins regardless of order + same mcpServers keys) = active profile
4. If no exact match: no profile is marked as active

### Step 3: Present

```markdown
## Plugin Profiles

| Profile | Description | Plugins | MCP Servers | Active |
|---------|-------------|---------|-------------|--------|
| daily | Everyday coding — keeper, superpowers, commit | 4 | 2 | * |
| plugin-dev | Plugin development with skill-creator | 6 | 0 | |
| review | Code review and analysis tools | 3 | 1 | |

*Active profile matches your current configuration.

**Commands:**
- `/profile-change <name>` — switch to a profile
- `/profile-create` — create a new profile
```

### Step 4: Show Detail (if few profiles)

If there are 3 or fewer profiles, also show the contents:

```markdown
### daily (active)
**Plugins:** forge-keeper, forge-superpowers, forge-commit, forge-security
**MCP Servers:** context7, serena

### plugin-dev
**Plugins:** forge-superpowers, forge-plugin-dev, skill-creator, forge-hookify
**MCP Servers:** (none)
```

## Edge Cases

- If `pluginConfigs["forge-profiles@dev-forge"].options.profiles` path doesn't exist: suggest `/profile-create`
- If current config doesn't match any profile: show "No active profile — current config doesn't match any saved profile"
- If profiles object is empty: same as no profiles found
