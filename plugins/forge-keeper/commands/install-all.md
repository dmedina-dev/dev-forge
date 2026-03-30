---
description: Install all dev-forge plugins. Skips forge-init if already bootstrapped, installs dependencies first, lets user exclude plugins. Shows plan and asks for confirmation.
---

Install all available plugins from the dev-forge marketplace.

## Process

### Step 1: Discover available plugins

List plugins from the dev-forge marketplace. Current catalog:

| Plugin | Description | Requires |
|--------|-------------|----------|
| forge-keeper | Context maintenance: sync, status, optimize + hooks | - |
| forge-superpowers | TDD, debugging, parallel agents, code review, worktrees, plans | - |
| forge-extended-dev | 4-phase workflow: feature-dev + deep-review + pr-review | forge-superpowers |
| forge-commit | Git commit and PR commands | - |
| forge-security | Security reminder hooks (9 vulnerability patterns) | - |
| forge-hookify | Custom hook rules engine with .local.md rules | - |
| forge-ralph | Persistent loop: Claude keeps working across stop events | - |
| forge-plugin-dev | Plugin development toolkit (7 skills, 3 agents) | - |
| forge-init | Project bootstrapper (disposable) | - |

Check which plugins are already installed in this project.

### Step 2: Determine what to skip

**forge-init**: Skip if project is already bootstrapped (CLAUDE.md + `.claude/` + `docs/sessions/` all exist).

**forge-plugin-dev**: Note it has a heavy context footprint — suggest installing only when developing plugins.

### Step 3: Resolve dependencies

From `docs/dependencies.md`:
- **forge-extended-dev requires forge-superpowers** — if user wants forge-extended-dev, forge-superpowers must install first
- All other plugins are independent

### Step 4: Present install plan

```
## Dev Forge — Install Plan

Already installed: [list or "none"]

### Will install (in order):
1. forge-keeper — context maintenance (recommended always-on)
2. forge-superpowers — core skills library
3. forge-extended-dev — extended workflow (requires forge-superpowers ✓)
4. forge-commit — commit/PR commands
5. forge-security — security hooks
6. forge-hookify — custom hook rules
7. forge-ralph — persistent loop

### Optional (not included by default):
- forge-plugin-dev — heavy context footprint, install when developing plugins

### Skipped:
- forge-init — project already bootstrapped ✓
  (or: included — project needs bootstrapping)

Want to exclude any plugins? Otherwise proceed.
```

The user may exclude plugins or add forge-plugin-dev. Adjust the plan.

### Step 5: Install in order

Install dependencies first, then dependents:
1. Independent plugins (any order)
2. forge-extended-dev last (after forge-superpowers is confirmed installed)

For each plugin:
```
/plugin install <name>
```

### Step 6: Post-install summary

```
Dev Forge — [N] plugins installed

Installed:
  forge-keeper ✓
  forge-superpowers ✓
  forge-extended-dev ✓
  forge-commit ✓
  forge-security ✓
  forge-hookify ✓
  forge-ralph ✓

Skipped:
  forge-init (already bootstrapped)
  forge-plugin-dev (optional — /plugin install forge-plugin-dev when needed)

Next steps:
  /forge-keeper:status — check context health
  /forge-init:init — bootstrap project (if forge-init was installed)
```
