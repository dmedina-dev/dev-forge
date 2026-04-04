---
description: "Create a plugin profile — interview to select which plugins are active for a work mode"
argument-hint: "[profile name]"
---

# Create Plugin Profile

Create a new profile that defines which plugins should be active for a specific work mode.
Profiles are stored in `.claude/settings.local.json` under the `forge-profiles` key (gitignored, personal).

## Process

### Step 1: Read Current Configuration

1. Read `.claude/settings.local.json`
2. Extract the current `plugins` array (active plugins)
3. Extract the current `mcpServers` object (active MCP servers)
4. If the file doesn't exist or keys are missing, start with empty list/object
5. For each plugin, extract a human-readable name from the identifier (last segment after `:` or directory basename)

### Step 2: Present Current Plugins

Show the user their currently installed plugins as a numbered checklist:

```markdown
## Currently Installed Plugins

These are your active plugins — the starting point for this profile.

| # | Plugin | Identifier |
|---|--------|------------|
| 1 | forge-keeper | marketplace:dmedina-dev/dev-forge:forge-keeper |
| 2 | forge-superpowers | marketplace:dmedina-dev/dev-forge:forge-superpowers |
| 3 | skill-creator | marketplace:claude-plugins-official:skill-creator |
| ... | ... | ... |

Which plugins do you want to **remove** from this profile? (numbers, comma-separated, or "none")
```

### Step 3: Present Current MCP Servers

Show configured MCP servers:

```markdown
## Currently Configured MCP Servers

| # | Server | Type | Command/URL |
|---|--------|------|-------------|
| 1 | context7 | stdio | npx @anthropic/context7 |
| 2 | serena | stdio | npx @anthropic/serena |
| ... | ... | ... | ... |

Which MCP servers do you want to **remove** from this profile? (numbers, comma-separated, or "none")
```

If no MCP servers are configured, skip this step and note it.

### Step 4: Ask About Additions

After removals:

```markdown
Do you want to **add** any plugins or MCP servers that aren't currently configured?
If yes, tell me which ones. Otherwise say "no".
```

This allows including items not currently active but desired in this profile.

### Step 5: Profile Metadata

If `$ARGUMENTS` contains a name, use it. Otherwise ask:

```markdown
## Profile Details

**Name:** (short, lowercase, hyphens — e.g., "daily", "plugin-dev", "review")
**Description:** (one line explaining when to use this profile)
```

### Step 6: Validation

Present the final profile for confirmation:

```markdown
## Profile Summary

**Name:** plugin-dev
**Description:** Plugin development — skill-creator, forge-plugin-dev, superpowers

**Plugins (N):**
- forge-superpowers
- forge-plugin-dev
- skill-creator

**MCP Servers (N):**
- context7 (stdio)

Save this profile?
```

**WAIT for explicit confirmation before saving.**

### Step 7: Save

1. Read `.claude/settings.local.json` (or create `{}` if it doesn't exist)
2. Ensure the `forge-profiles` key exists (create as `{}` if missing)
3. Add the new profile:

```json
{
  "forge-profiles": {
    "<name>": {
      "description": "<description>",
      "plugins": ["<exact-identifier>", "..."],
      "mcpServers": { "<server-name>": { "...config..." } },
      "created_at": "<YYYY-MM-DD>"
    }
  }
}
```

4. Write back the FULL file (preserve all other keys: plugins, permissions, env, etc.)
5. Validate: `python3 -m json.tool .claude/settings.local.json`
6. Confirm: "Profile **<name>** saved. Switch to it with `/profile-change <name>`."

## Edge Cases

- If `.claude/settings.local.json` doesn't exist: create it with just `{ "forge-profiles": { ... } }`
- If a profile with the same name already exists: warn and ask whether to overwrite
- If the user wants 0 plugins: allow it — a "clean slate" profile is valid
- If write fails: report error, do NOT leave a partial file
