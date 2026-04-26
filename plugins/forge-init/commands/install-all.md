---
description: Install all dev-forge working plugins. Configuration plugins (forge-init, forge-plugin-dev, forge-context-mcp, forge-export) are shown separately — install them on demand. Resolves dependencies and lets user exclude plugins.
---

Install all dev-forge **working** plugins — the daily driver set.

## Plugin catalog

### Working plugins (installed by this command)

Always-on plugins for daily development work.

| Plugin | Description | Requires |
|--------|-------------|----------|
| forge-keeper | Context maintenance: sync, status, recall, segment-doc + hooks | - |
| forge-superpowers | TDD, debugging, parallel agents, code review, worktrees, plans | - |
| forge-deep-review | Specialized review agents + automated PR review | - |
| forge-brainstorming | Teammate-driven full lifecycle with 5 persistent agents | forge-superpowers |
| forge-commit | Git commit and PR commands | - |
| forge-security | Security reminder hooks (9 vulnerability patterns) | - |
| forge-hookify | Custom hook rules engine with .local.md rules | - |
| forge-profiles | Plugin profile manager — switch plugin sets per work mode | - |
| forge-frontend-design | Distinctive, production-grade UI/UX design | - |
| forge-ui-forge | Iterative UI prototyping with click-to-annotate overlay | - |
| forge-telegram | Telegram bridge — listener + sender (bash + Monitor) | - |
| forge-proactive-qa | Autonomous Playwright QA agent (Telegram-notified) | - |

### Configuration plugins (NOT installed by this command)

Install when needed, uninstall after — they consume context without adding
value when not actively being used.

| Plugin | Purpose | When to install |
|--------|---------|-----------------|
| forge-init | Project bootstrapper | New project → `/plugin install forge-init` → `/forge-init:init` → uninstall |
| forge-plugin-dev | Plugin development toolkit | Developing plugins → `/plugin install forge-plugin-dev` → build → uninstall |
| forge-context-mcp | MCP server setup guide (Context7, Serena, XRAY) | Setting up codebase intelligence → configure → uninstall |
| forge-export | Marketplace export wizard | Forking dev-forge for another org → export → uninstall |

## Process

### Step 1: Check what's already installed

List plugins already installed in this project to avoid reinstalling.

### Step 2: Resolve dependencies

- **forge-brainstorming requires forge-superpowers** — install superpowers first
- All other working plugins are independent

### Step 3: Present install plan

```
## Dev Forge — Working Plugins Install Plan

Already installed: [list or "none"]

### Will install (in order):
1. forge-keeper — context maintenance
2. forge-superpowers — core skills library
3. forge-brainstorming — teammate-driven lifecycle (requires forge-superpowers ✓)
4. forge-deep-review — specialized review agents + PR automation
5. forge-commit — commit/PR commands
6. forge-security — security hooks
7. forge-hookify — custom hook rules
8. forge-profiles — plugin profile manager
9. forge-frontend-design — UI/UX design
10. forge-ui-forge — UI prototyping
11. forge-telegram — Telegram bridge
12. forge-proactive-qa — autonomous QA agent

### Not included (configuration plugins — install on demand):
- forge-plugin-dev → /plugin install forge-plugin-dev (for plugin development)
- forge-context-mcp → /plugin install forge-context-mcp (for MCP setup)
- forge-export → /plugin install forge-export (for marketplace forking)

Want to exclude any working plugins? Otherwise proceed.
```

The user may exclude plugins from the working set. Adjust the plan.

### Step 4: Install in order

1. forge-superpowers first (dependency for forge-brainstorming)
2. All other independent plugins
3. forge-brainstorming last

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
  forge-brainstorming ✓
  forge-deep-review ✓
  forge-commit ✓
  forge-security ✓
  forge-hookify ✓
  forge-profiles ✓
  forge-frontend-design ✓
  forge-ui-forge ✓
  forge-telegram ✓
  forge-proactive-qa ✓

Configuration (install when needed):
  forge-plugin-dev → /plugin install forge-plugin-dev
  forge-context-mcp → /plugin install forge-context-mcp
  forge-export → /plugin install forge-export

Next: /forge-keeper:status
```
