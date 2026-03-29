# Dev Forge

A personal GitHub plugin marketplace for Claude Code built around one principle:
**the plugin provides procedures, the project provides knowledge.**

## The Engine / Fuel Separation

**Engine** (this marketplace): Generic, reusable plugins that know HOW to maintain
context. Update the engine once, all projects benefit.

**Fuel** (your project): CLAUDE.md files, `.claude/rules/`, `docs/sessions/`, ADRs.
Created by the plugins, version-controlled in your repo. Survives independently
of the plugins.

## Plugins

| Plugin | Purpose | Lifecycle |
|--------|---------|-----------|
| **forge-init** | Two-step bootstrapper: runs native `/init`, then layers conventions | Disposable — uninstall after use |
| **forge-keeper** | Keeps CLAUDE.md, docs, and memories in sync across sessions | Permanent |

## Installation

```bash
# Add marketplace (once per machine)
/plugin marketplace add dmedina-dev/dev-forge

# New project setup
/plugin install forge-init
/plugin install forge-keeper

# Bootstrap the project
/forge-init:init

# Uninstall forge-init after bootstrap
# /plugin → Manage and uninstall plugins → forge-init → Uninstall
```

## Usage

### forge-init

Run `/forge-init:init` in a new or existing project. It will:

1. **Foundation** — Run the native `/init` interview to generate base config
2. **Conventions** — Audit and improve with best practices:
   - CLAUDE.md quality (200-line limit, WHY/WHAT/HOW structure)
   - Per-directory CLAUDE.md for zones `/init` missed
   - Path-scoped `.claude/rules/` for cross-cutting conventions
   - Documentation scaffolding (`docs/sessions/`, `docs/adr/`)
   - Personal overrides (`CLAUDE.local.md`)

All changes require your approval. After bootstrap, uninstall forge-init.

### forge-keeper

Stays installed permanently. Three ways it activates:

- **Semantic detection** — Claude detects you've shifted context (e.g., from auth
  to payments) and suggests running `/forge-keeper:sync`
- **Explicit command** — Run `/forge-keeper:sync` anytime to capture session changes
- **Safety net hook** — Monitors git activity and reminds when thresholds are exceeded

Commands:
- `/forge-keeper:sync` — Analyze changes, propose CLAUDE.md updates, generate session summary
- `/forge-keeper:status` — Context health report with drift detection
- `/forge-keeper:optimize` — Deep restructuring after plugin updates — audits project config against current engine capabilities

## Configuration

### Environment variables (forge-keeper hook thresholds)

| Variable | Default | Description |
|----------|---------|-------------|
| `FK_MIN_FILES` | 20 | Minimum changed files to trigger reminder |
| `FK_MIN_ZONES` | 3 | Minimum zones touched to trigger reminder |
| `FK_COOLDOWN` | 15 | Minimum prompts between reminders |

### Team auto-install

Add to your project's `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "dev-forge": {
      "source": { "source": "github", "repo": "dmedina-dev/dev-forge" }
    }
  }
}
```

## Future Plugins

Each follows engine/fuel: procedures in the plugin, knowledge in the project.

- **ddd-scaffold** — Domain/bounded context boilerplate generation
- **nest-patterns** — NestJS module/service/controller conventions
- **test-guardian** — TDD/BDD workflow enforcement via hooks
- **deploy-checklist** — Pre-deployment verification skill

## License

MIT
