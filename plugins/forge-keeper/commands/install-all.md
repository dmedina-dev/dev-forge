---
description: Install all dev-forge plugins. Skips forge-init if the project already has CLAUDE.md and .claude/ (already bootstrapped). Lists what will be installed and asks for confirmation before proceeding.
---

Install all available plugins from the dev-forge marketplace.

## Process

### Step 1: Read the marketplace catalog

Read the marketplace.json from the dev-forge repository to get the full list
of available plugins. The marketplace URL is:
`https://github.com/dmedina-dev/dev-forge`

If you can't read the remote, check if the marketplace is already registered
locally and list its plugins.

### Step 2: Detect if project is already bootstrapped

Check for signs that forge-init has already run:
- CLAUDE.md exists at project root
- `.claude/` directory exists
- `docs/sessions/` exists

If ALL three exist → project is bootstrapped → skip forge-init.
If ANY is missing → include forge-init in the install list.

### Step 3: Present the install plan

Show the user what will be installed:

```
## Dev Forge — Install Plan

### Will install:
- forge-keeper (context maintenance, hooks, sync/status/optimize)
- forge-tdd (TDD workflow)
- forge-agents (work agents)
- ... (all other available plugins)

### Skipped:
- forge-init (project already bootstrapped ✓)

Proceed? (yes/no)
```

### Step 4: Install

After user confirms, install each plugin:

```
/plugin install <name>
```

Report progress as each plugin installs.

### Step 5: Confirm

```
Dev Forge installed:
- forge-keeper ✓
- forge-tdd ✓
- forge-agents ✓

Skipped:
- forge-init (already bootstrapped)

Run /forge-keeper:status to check context health.
```
