---
description: "Switch to a plugin profile — updates active plugins to match the target profile"
argument-hint: "[profile name]"
---

# Change Plugin Profile

Switch to a different plugin profile. This modifies the `plugins` key in `.claude/settings.local.json`
to activate only the plugins defined in the target profile.

**Target profile:** $ARGUMENTS

## Process

### Step 1: Select Profile

1. Read `.claude/settings.local.json` and extract the `forge-profiles` object
2. If no `forge-profiles` key or empty: "No profiles found. Create one with `/profile-create`." and stop

**If `$ARGUMENTS` specifies a profile name:**
3. Check if that name exists in `forge-profiles`
4. If not: list available profiles and ask user to pick

**If `$ARGUMENTS` is empty:**
3. List all profiles (name, description, plugin count, active indicator)
4. Ask: "Which profile do you want to switch to?"
5. Wait for user selection

### Step 2: Calculate Diff

1. Get current `plugins` array and `mcpServers` object from settings.local.json
2. Get target profile's `plugins` and `mcpServers` from `forge-profiles.<name>`
3. Calculate plugin diff:
   - **Install**: plugins in target but not in current
   - **Uninstall**: plugins in current but not in target
   - **Keep**: plugins in both
4. Calculate MCP server diff:
   - **Add**: servers in target but not in current
   - **Remove**: servers in current but not in target
   - **Keep**: servers in both

### Step 3: Present Diff

```markdown
## Switching to: <profile-name>
> <profile-description>

### Plugin Changes

**Install (N):**
+ forge-plugin-dev
+ skill-creator

**Uninstall (N):**
- forge-brainstorming
- forge-extended-dev

**Keep (N):**
= forge-superpowers
= forge-keeper

### MCP Server Changes

**Add (N):**
+ context7

**Remove (N):**
- serena

**Keep (N):**
= (none)

Apply these changes?
```

If no changes needed (both plugins and mcpServers already match): "You're already on this profile. No changes needed." and stop.

**WAIT for explicit confirmation before applying.**

### Step 4: Apply Changes

1. Read the FULL `.claude/settings.local.json`
2. Replace the `plugins` key with the target profile's plugins array
3. Replace the `mcpServers` key with the target profile's mcpServers object
4. Write the complete file back

**CRITICAL:** Only modify `plugins` and `mcpServers`. Do NOT touch permissions, env,
forge-profiles, or any other key. Read entire file → change two keys → write entire file.

5. Validate: `python3 -m json.tool .claude/settings.local.json`

### Step 5: Reload

```markdown
Profile **<name>** applied.

Run `/reload-plugins` to activate the new configuration.
```

## Edge Cases

- If `.claude/settings.local.json` doesn't exist: "No settings file found. Create a profile first with `/profile-create`."
- If target profile has plugins that might not exist anymore: warn but apply (user may have local paths)
- If target profile has no `mcpServers` key: treat as empty object (remove all current servers)
- If write fails (permissions, disk): report error, do NOT leave a partial settings file
- If current `plugins` or `mcpServers` keys don't exist: treat as empty (all target items will be additions)
