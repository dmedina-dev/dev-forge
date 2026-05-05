---
description: Install all dev-forge working plugins. Configuration plugins (forge-context-mcp, forge-export, forge-init, forge-plugin-dev) are shown separately — install them on demand. Resolves dependencies and lets user exclude plugins.
---

Install all dev-forge **working** plugins — the daily driver set.

> Generated from `.claude-plugin/marketplace.json` by `scripts/generate-install-all.sh`. Do not hand-edit; run the script and commit the diff.

## Plugin catalog

### Working plugins (installed by this command)

Always-on plugins for daily development work.

| Plugin | Description | Requires |
|--------|-------------|----------|
| forge-keeper | Context maintenance: sync, status, recall, segment-doc + hooks | - |
| forge-superpowers | TDD, debugging, parallel agents, code review, worktrees, plans | - |
| forge-deep-review | Specialized review agents + automated PR review | - |
| forge-hookify | Custom hook rules engine with .local.md rules | - |
| forge-security | Security reminder hooks (9 vulnerability patterns) | - |
| forge-commit | Git commit and PR commands | - |
| forge-frontend-design | Distinctive, production-grade UI/UX design | - |
| forge-telegram | Telegram bridge — listener + sender (bash + Monitor) | - |
| forge-proactive-qa | Autonomous Playwright QA agent (Telegram-notified) | - |
| forge-brainstorming | Teammate-driven full lifecycle with 5 persistent agents | forge-superpowers |
| forge-profiles | Plugin profile manager — switch plugin sets per work mode | - |
| forge-mattpocock | Alternative skills framework: grill / to-prd (waves) / tdd / diagnose / improve-architecture / zoom-out / caveman | - |
| forge-ui-forge | Iterative UI prototyping + live overlay over an existing dev server | - |
| forge-deepthink | Structured /deepthink protocol — pre-filled 7-slot interview, audit-ready response with red team, pre-mortem, and assumption audit | - |

### Configuration plugins (NOT installed by this command)

Install when needed, uninstall after — they consume context without adding
value when not actively being used.

| Plugin | Purpose | When to install |
|--------|---------|-----------------|
| forge-init | Project bootstrapper + migrate-from-forge helper | New project → `/plugin install forge-init` → `/forge-init:init` → uninstall |
| forge-plugin-dev | Plugin development toolkit | Developing plugins → `/plugin install forge-plugin-dev` → build → uninstall |
| forge-context-mcp | MCP server setup guide (Context7, Serena, XRAY) | Setting up codebase intelligence → configure → uninstall |
| forge-export | Marketplace export wizard | Forking dev-forge for another org → export → uninstall |

## Process

### Step 1: Check what's already installed

List plugins already installed in this project to avoid reinstalling.

### Step 2: Resolve dependencies

- **forge-brainstorming requires forge-superpowers** — install forge-superpowers first
- All other working plugins are independent

### Step 3: Present install plan

```
## Dev Forge — Working Plugins Install Plan

Already installed: [list or "none"]

### Will install (in order):
1. forge-keeper — Context maintenance: sync, status, recall, segment-doc + hooks
2. forge-superpowers — TDD, debugging, parallel agents, code review, worktrees, plans
3. forge-deep-review — Specialized review agents + automated PR review
4. forge-hookify — Custom hook rules engine with .local.md rules
5. forge-security — Security reminder hooks (9 vulnerability patterns)
6. forge-commit — Git commit and PR commands
7. forge-frontend-design — Distinctive, production-grade UI/UX design
8. forge-telegram — Telegram bridge — listener + sender (bash + Monitor)
9. forge-proactive-qa — Autonomous Playwright QA agent (Telegram-notified)
10. forge-brainstorming — Teammate-driven full lifecycle with 5 persistent agents (requires forge-superpowers ✓)
11. forge-profiles — Plugin profile manager — switch plugin sets per work mode
12. forge-mattpocock — Alternative skills framework: grill / to-prd (waves) / tdd / diagnose / improve-architecture / zoom-out / caveman
13. forge-ui-forge — Iterative UI prototyping + live overlay over an existing dev server
14. forge-deepthink — Structured /deepthink protocol — pre-filled 7-slot interview, audit-ready response with red team, pre-mortem, and assumption audit

### Not included (configuration plugins — install on demand):
- forge-init → /plugin install forge-init (New project)
- forge-plugin-dev → /plugin install forge-plugin-dev (Developing plugins)
- forge-context-mcp → /plugin install forge-context-mcp (Setting up codebase intelligence)
- forge-export → /plugin install forge-export (Forking dev-forge for another org)

Want to exclude any working plugins? Otherwise proceed.
```

The user may exclude plugins from the working set. Adjust the plan.

### Step 4: Install in order

1. forge-keeper
2. forge-superpowers (dependency first)
3. forge-deep-review
4. forge-hookify
5. forge-security
6. forge-commit
7. forge-frontend-design
8. forge-telegram
9. forge-proactive-qa
10. forge-brainstorming
11. forge-profiles
12. forge-mattpocock
13. forge-ui-forge
14. forge-deepthink

For each:
```
/plugin install <name>
```

### Step 5: Post-install summary

```
Dev Forge — 14 working plugins installed

Working:
  forge-keeper ✓
  forge-superpowers ✓
  forge-deep-review ✓
  forge-hookify ✓
  forge-security ✓
  forge-commit ✓
  forge-frontend-design ✓
  forge-telegram ✓
  forge-proactive-qa ✓
  forge-brainstorming ✓
  forge-profiles ✓
  forge-mattpocock ✓
  forge-ui-forge ✓
  forge-deepthink ✓

Configuration (install when needed):
  forge-init → /plugin install forge-init
  forge-plugin-dev → /plugin install forge-plugin-dev
  forge-context-mcp → /plugin install forge-context-mcp
  forge-export → /plugin install forge-export

Next: /forge-keeper:status
```
