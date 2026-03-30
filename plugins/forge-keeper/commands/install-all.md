---
description: Install all dev-forge working plugins. Configuration plugins (forge-init, forge-plugin-dev) are shown separately — install them on demand. Resolves dependencies and lets user exclude plugins.
---

Install all dev-forge **working** plugins — the daily driver set.

## Plugin catalog

### Working plugins (installed by this command)

Always-on plugins for daily development work.

| Plugin | Description | Requires |
|--------|-------------|----------|
| forge-keeper | Context maintenance: sync, status, optimize + hooks | - |
| forge-superpowers | TDD, debugging, parallel agents, code review, worktrees, plans | - |
| forge-extended-dev | 4-phase workflow: feature-dev + deep-review + pr-review | forge-superpowers |
| forge-commit | Git commit and PR commands | - |
| forge-security | Security reminder hooks (9 vulnerability patterns) | - |
| forge-hookify | Custom hook rules engine with .local.md rules | - |
| forge-ralph | Persistent loop: Claude keeps working across stop events | - |

### Configuration plugins (NOT installed by this command)

Install when needed, uninstall after — they consume context without adding
value when not actively being used.

| Plugin | Purpose | When to install |
|--------|---------|-----------------|
| forge-init | Project bootstrapper | New project → `/plugin install forge-init` → `/forge-init:init` → uninstall |
| forge-plugin-dev | Plugin development toolkit | Developing plugins → `/plugin install forge-plugin-dev` → build → uninstall |

## Process

### Step 1: Check what's already installed

List plugins already installed in this project to avoid reinstalling.

### Step 2: Resolve dependencies

- **forge-extended-dev requires forge-superpowers** — install superpowers first
- All other working plugins are independent

### Step 3: Present install plan

```
## Dev Forge — Working Plugins Install Plan

Already installed: [list or "none"]

### Will install (in order):
1. forge-keeper — context maintenance
2. forge-superpowers — core skills library
3. forge-extended-dev — extended workflow (requires forge-superpowers ✓)
4. forge-commit — commit/PR commands
5. forge-security — security hooks
6. forge-hookify — custom hook rules
7. forge-ralph — persistent loop

### Not included (configuration plugins — install on demand):
- forge-init → /plugin install forge-init (for new projects)
- forge-plugin-dev → /plugin install forge-plugin-dev (for plugin development)

Want to exclude any working plugins? Otherwise proceed.
```

The user may exclude plugins from the working set. Adjust the plan.

### Step 4: Install in order

1. forge-superpowers first (dependency for forge-extended-dev)
2. All other independent plugins
3. forge-extended-dev last

For each:
```
/plugin install <name>
```

### Step 5: Post-install summary

```
Dev Forge — [N] working plugins installed

Working:
  forge-keeper ✓
  forge-superpowers ✓
  forge-extended-dev ✓
  forge-commit ✓
  forge-security ✓
  forge-hookify ✓
  forge-ralph ✓

Configuration (install when needed):
  forge-init → /plugin install forge-init
  forge-plugin-dev → /plugin install forge-plugin-dev

Next: /forge-keeper:status
```
