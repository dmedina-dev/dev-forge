# Dev Forge

A personal Claude Code plugin marketplace built around one principle: **plugins provide procedures, projects provide knowledge.**

## The problem

Claude Code is powerful but its context drifts. After long sessions, your CLAUDE.md files go stale, architectural decisions stay undocumented, and the next session starts with outdated context. Setting up a new project means manually configuring `.claude/`, writing CLAUDE.md files from scratch, and hoping you remember your own conventions.

## The solution

Dev Forge packages two plugins that handle the full lifecycle of project context — from initial setup to ongoing maintenance — while keeping all project-specific knowledge in your repo under version control.

### Engine / Fuel separation

**Engine** (this marketplace) — Generic, reusable procedures that know HOW to manage context but carry no project-specific content. Update once, all projects benefit.

**Fuel** (your project repo) — CLAUDE.md files, `.claude/rules/`, `docs/sessions/`, ADRs. Created during initialization, enriched with every development session. Lives in your repo, versioned with your code.

## Plugins

### forge-init *(disposable — uninstall after use)*

Two-step project bootstrapper:

1. **Foundation** — Runs the native `/init` with `CLAUDE_CODE_NEW_INIT=1` to interview you about your project, workflows and preferences. Generates base configuration from intent, not just file inspection.
2. **Conventions layer** — Audits and improves the `/init` output: enforces CLAUDE.md best practices (200-line limit, WHY/WHAT/HOW structure), fills per-directory context gaps, adds path-scoped `.claude/rules/`, scaffolds `docs/sessions/` and `docs/adr/`.

All changes require your explicit approval. After setup, uninstall it — the conventions live in your project, not the plugin.

### session-keeper *(permanent)*

Ongoing context maintenance with three components:

- **`/session-keeper:sync`** — Analyzes `git diff`, classifies changes by monorepo zone, proposes CLAUDE.md updates, generates session summaries. Every change needs your approval.
- **`/session-keeper:status`** — Quick health report showing context drift, CLAUDE.md freshness and rules coverage.
- **Context-aware hook** — Monitors git activity in the background. When enough real work accumulates (10+ files across 2+ zones), shows a reminder with a zone breakdown — not a blind timer, but an activity-based trigger.

## Quick start

```bash
# Add the marketplace (once per machine)
/plugin marketplace add YOUR_USER/dev-forge

# New project setup
/plugin install forge-init@YOUR_USER
/plugin install session-keeper@YOUR_USER
/forge-init:init

# After setup completes, uninstall the bootstrapper
# /plugin → Manage and uninstall plugins → forge-init → Uninstall

# From here on, session-keeper handles everything:
# • Work normally — the context watcher monitors in the background
# • When reminded, run /session-keeper:sync
# • Check health anytime with /session-keeper:status
```

## What your project looks like after setup

```
your-project/
├── CLAUDE.md                     # Project-wide context (~200 lines)
├── CLAUDE.local.md               # Personal overrides (gitignored)
├── apps/
│   ├── api/CLAUDE.md             # Backend-specific context
│   └── web/CLAUDE.md             # Frontend-specific context
├── domains/CLAUDE.md             # DDD conventions
├── shared/CLAUDE.md              # Cross-package impact rules
├── .claude/
│   ├── settings.json
│   └── rules/                    # Path-scoped cross-cutting rules
│       ├── testing.md
│       └── security.md
└── docs/
    ├── sessions/                 # Session summaries from /sync
    └── adr/                      # Architecture Decision Records
```

Everything above is version-controlled in your project. The plugins just know how to create and maintain it.

## Configuration

The context watcher thresholds are configurable via environment variables:

| Variable | Default | What it controls |
|---|---|---|
| `SK_MIN_FILES` | 10 | Minimum changed files before any reminder |
| `SK_MIN_ZONES` | 2 | Minimum distinct top-level directories touched |
| `SK_COOLDOWN` | 8 | Minimum prompts between reminders |

## License

MIT
