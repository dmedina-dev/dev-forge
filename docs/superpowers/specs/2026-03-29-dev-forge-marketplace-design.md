# Dev Forge — Marketplace Design Spec

> **Date:** 2026-03-29
> **Status:** approved
> **Scope:** Full marketplace with two plugins (forge-init + forge-keeper)

---

## Core idea

Dev Forge is a personal GitHub plugin marketplace for Claude Code built around one principle: **the plugin provides procedures, the project provides knowledge.**

**Engine** (marketplace plugins): Generic, reusable procedures that know HOW to maintain context. Update the engine once, all projects benefit.

**Fuel** (project repo): CLAUDE.md files, `.claude/rules/`, `docs/sessions/`, ADRs. Created by the plugins, version-controlled in each project. Survives independently of the plugins.

---

## Architecture

```
dev-forge/                              ← marketplace repo (dmedina-dev/dev-forge)
├── .claude-plugin/
│   └── marketplace.json                ← registry: lists plugins with git-subdir source
├── plugins/
│   ├── forge-init/                     ← disposable plugin (bootstrap)
│   │   ├── .claude-plugin/plugin.json
│   │   ├── skills/forge-init/
│   │   │   ├── SKILL.md               ← main skill (trigger + procedure)
│   │   │   └── references/
│   │   │       ├── claudemd-conventions.md  ← CLAUDE.md creation guide
│   │   │       └── manual-discovery.md      ← fallback without /init
│   │   └── commands/
│   │       └── init.md                 ← /forge-init:init entry point
│   └── forge-keeper/                 ← permanent plugin (maintenance)
│       ├── .claude-plugin/plugin.json
│       ├── skills/forge-keeper/
│       │   ├── SKILL.md               ← main skill (semantic trigger)
│       │   └── references/
│       │       ├── claudemd-guide.md        ← CLAUDE.md maintenance guide
│       │       └── monorepo-patterns.md     ← monorepo patterns
│       ├── commands/
│       │   ├── sync.md                 ← /forge-keeper:sync
│       │   └── status.md              ← /forge-keeper:status
│       ├── hooks/hooks.json            ← UserPromptSubmit → context watcher
│       └── scripts/
│           ├── context-watch.sh        ← monitors git activity (safety net)
│           └── reset-watch.sh          ← resets watcher state
├── README.md
└── LICENSE
```

---

## Marketplace manifest

Monorepo approach using `git-subdir` source type. Both plugins embedded in the same repo.

```json
{
  "name": "dev-forge",
  "owner": {
    "name": "dmedina",
    "email": "me@dmedina.dev"
  },
  "metadata": {
    "description": "Dev Forge — opinionated Claude Code plugins for project bootstrapping and ongoing context maintenance.",
    "version": "1.0.0"
  },
  "plugins": [
    {
      "name": "forge-init",
      "description": "Two-step project bootstrapper: runs native /init, then layers conventions.",
      "source": {
        "source": "git-subdir",
        "url": "https://github.com/dmedina-dev/dev-forge.git",
        "path": "plugins/forge-init"
      },
      "version": "1.0.0"
    },
    {
      "name": "forge-keeper",
      "description": "Keeps CLAUDE.md, docs and memories in sync across sessions.",
      "source": {
        "source": "git-subdir",
        "url": "https://github.com/dmedina-dev/dev-forge.git",
        "path": "plugins/forge-keeper"
      },
      "version": "1.0.0"
    }
  ]
}
```

---

## Plugin 1: forge-init (disposable)

### Purpose

Two-step bootstrapper. Use once per project, then uninstall to free context window.

### Step 1 — Foundation

Runs native `/init` with `CLAUDE_CODE_NEW_INIT=1` to interview the developer and generate base configuration:
- Root CLAUDE.md (and possibly per-directory ones)
- Skills and hooks based on the interview
- `.claude/` configuration

If `/init` is unavailable or the experimental flag doesn't work, falls back to the manual discovery process in `references/manual-discovery.md`.

### Step 2 — Conventions layer

Audits what `/init` produced and layers on top:

**2.1 CLAUDE.md quality audit**
- Under ~200 lines? WHY/WHAT/HOW structure? No duplicated linter rules?
- Specific, verifiable instructions? Nothing Claude already knows?
- Proposes improvements as diff for human approval.

**2.2 Per-directory gap fill**
- Scans project structure for directories that deserve CLAUDE.md but didn't get one
- Each app in `apps/`, domain directories, shared libraries, infrastructure
- Children under ~100 lines, supplement root, don't repeat it

**2.3 Path-scoped rules**
- Creates/completes `.claude/rules/` with cross-cutting rules
- Testing conventions → `paths: **/*.test.ts, **/*.spec.ts`
- Security rules → `paths: domains/**, shared/auth/**`
- Style conventions as needed

**2.4 Documentation scaffolding**
- `docs/sessions/` with `.gitkeep`
- `docs/adr/` with ADR template (`0001-template.md`)

**2.5 Personal overrides**
- `CLAUDE.local.md` (gitignored) for developer-specific preferences

**2.6 Initialization report**
- `docs/sessions/YYYY-MM-DD-forge-init.md` documenting what was discovered, added, improved

**2.7 Human confirmation gate**
- Presents complete summary of all changes
- Nothing written until human explicitly confirms

### Step 3 — Self-cleanup

After initialization is approved, reminds user to uninstall forge-init via `/plugin`.

### Files

| File | Purpose |
|------|---------|
| `.claude-plugin/plugin.json` | Plugin manifest |
| `skills/forge-init/SKILL.md` | Main skill with trigger description and full procedure |
| `skills/forge-init/references/claudemd-conventions.md` | Guide for creating quality CLAUDE.md — 200-line limit, WHY/WHAT/HOW, @imports, sections (Stack, Commands, Architecture, Conventions, Gotchas), what to include/exclude, pruning |
| `skills/forge-init/references/manual-discovery.md` | Fallback procedure: project scan, stack detection, directory mapping, interview, CLAUDE.md generation |
| `commands/init.md` | `/forge-init:init` — entry point that invokes the skill |

---

## Plugin 2: forge-keeper (permanent)

### Purpose

Keeps project context synchronized across Claude Code sessions. Three components: semantic trigger, commands, and safety net hook.

### Two-tier trigger system

**Primary — Agent semantic detection (SKILL.md description)**

The skill description is written so Claude detects semantic context shifts:
- Conversation moves between different domain areas
- Shift from one bounded context to another
- Jump from frontend to backend or across monorepo zones
- Significant architectural decisions being made

Claude proactively suggests `/forge-keeper:sync` when detecting drift. The description will be refined iteratively using skill-creator with evals against real conversations.

**Secondary — Hook safety net (context-watch.sh)**

Shell script hook on `UserPromptSubmit` with relaxed thresholds:
- `FK_MIN_FILES=20` — minimum changed files
- `FK_MIN_ZONES=3` — minimum zones touched
- `FK_COOLDOWN=15` — minimum prompts since last reminder
- Must have new activity since last check

State persisted in `/tmp/forge-keeper/state.json`. Non-blocking, always exit 0.

Hook command uses `bash ${CLAUDE_PLUGIN_ROOT}/scripts/context-watch.sh` for correct path resolution.

### `/forge-keeper:sync` — On-demand synchronization

Six-step procedure:

1. **Analyze changes** — `git diff --name-only` to identify changed files
2. **Classify by zone** — group by top-level directory
3. **Propose CLAUDE.md updates** — per zone, respecting limits (~200 root, ~100 children). New conventions, changed commands, architectural decisions, gotchas, dependencies
4. **Propose `.claude/rules/`** — if new cross-cutting conventions emerged
5. **Generate session summary** — `docs/sessions/YYYY-MM-DD-title.md` with changes, decisions, status, context for next session
6. **Present and confirm** — show all proposed changes, wait for human approval. After applying, run `reset-watch.sh`

### `/forge-keeper:status` — Health check

Generates context health report:
- All CLAUDE.md files with last modification date
- `.claude/rules/` files with path scopes
- Drift detection: zones where code changed but context didn't
- Last session summary

Output format:
```
Context health — [project]

CLAUDE.md             Last updated       Drift?
─────────────────────────────────────────────────
./CLAUDE.md           2 days ago         ⚠️ 12 files changed
apps/api/CLAUDE.md    1 week ago         ✅ no changes
apps/web/CLAUDE.md    does not exist     🔴 43 files without context
shared/CLAUDE.md      3 days ago         ⚠️ 5 files changed

Rules                 Scope
─────────────────────────────────────────────────
testing.md            **/*.test.ts, **/*.spec.ts
security.md           domains/**, shared/auth/**

Last session: 2026-03-25 — "Refactor auth module"
```

### Files

| File | Purpose |
|------|---------|
| `.claude-plugin/plugin.json` | Plugin manifest |
| `skills/forge-keeper/SKILL.md` | Main skill with semantic trigger and sync procedure |
| `skills/forge-keeper/references/claudemd-guide.md` | Guide for maintaining CLAUDE.md — incremental updates, when to prune, when to update, conflict resolution between root and children |
| `skills/forge-keeper/references/monorepo-patterns.md` | Root vs child scope, path-scoped rules, lazy loading, claudeMdExcludes, conflict resolution |
| `commands/sync.md` | `/forge-keeper:sync` entry point |
| `commands/status.md` | `/forge-keeper:status` entry point |
| `hooks/hooks.json` | UserPromptSubmit → context-watch.sh |
| `scripts/context-watch.sh` | Git activity monitor with relaxed thresholds |
| `scripts/reset-watch.sh` | Resets watcher state |

---

## Distribution

### Installation flow

```bash
# Register marketplace (once per machine)
/plugin marketplace add dmedina-dev/dev-forge

# New project setup
/plugin install forge-init
/plugin install forge-keeper
/forge-init:init          # Step 1: /init interview → Step 2: conventions
# Uninstall forge-init after

# Ongoing work
# Semantic trigger detects context shift → suggests /forge-keeper:sync
# Safety net hook reminds at high thresholds
# Human runs /forge-keeper:sync → approve changes

# Health check
/forge-keeper:status
```

### Team auto-install

Add to project's `.claude/settings.json`:
```json
{
  "extraKnownMarketplaces": {
    "dev-forge": {
      "source": { "source": "github", "repo": "dmedina-dev/dev-forge" }
    }
  }
}
```

### Updates

`/plugin marketplace update` pulls latest from the repo. Reference files (guides, patterns) improve in the engine and propagate to all projects.

---

## Testing and validation

### Local development

```bash
# Test forge-init
claude --plugin-dir /path/to/dev-forge/plugins/forge-init

# Test forge-keeper
claude --plugin-dir /path/to/dev-forge/plugins/forge-keeper

# Test both
claude --plugin-dir /path/to/dev-forge/plugins/forge-init \
       --plugin-dir /path/to/dev-forge/plugins/forge-keeper
```

### Verification checklist

1. `/forge-init:init` → executes `/init` or manual fallback, then conventions layer
2. `/forge-keeper:status` → lists CLAUDE.md, drift, rules
3. `/forge-keeper:sync` → analyzes diff, proposes changes, waits for confirmation
4. Semantic trigger → shift topics in conversation, verify sync suggestion
5. Hook safety net → accumulate activity, verify reminder at high thresholds

### Iteration plan

Use skill-creator to run evals on forge-keeper's semantic trigger, refining the SKILL.md description with tests across real project branches.

---

## Design decisions

**Why monorepo with git-subdir:** Single repo, single push updates everything. `git-subdir` source type is supported by Claude Code's plugin system. Migration to separate repos is trivial if needed — only marketplace.json changes.

**Why forge-init wraps /init instead of replacing it:** Native `/init` with `CLAUDE_CODE_NEW_INIT=1` does the hard part — interviewing and mapping intent. Building a competing interview would duplicate effort. forge-init adds the opinionated layer `/init` doesn't cover.

**Why forge-init is disposable:** Its skill description occupies context window space every session. After bootstrapping, that's waste. The conventions it created live in the project.

**Why two-tier trigger for forge-keeper:** Claude can detect semantic context shifts (domain changes, concept jumps) that file counts cannot. The hook acts as safety net with relaxed thresholds, not the primary trigger. Semantic detection will be refined iteratively with skill-creator evals.

**Why the hook uses git diff, not prompt count:** Activity-based thresholds are more useful than time-based ones. 20 questions about one file ≠ context drift. 5 prompts across 3 packages = needs sync.

**Why reference files are separate per plugin:** forge-init focuses on CLAUDE.md creation, forge-keeper on maintenance. Different angles, some shared concepts, but each plugin is self-contained and independently installable.

**Why forge-keeper references are generic:** Best practices for CLAUDE.md and monorepo patterns apply to any project. They belong in the engine so improvements propagate everywhere. Project-specific rules go in `.claude/rules/` (fuel).

---

## forge-keeper:optimize — Deep restructuring

### Purpose

When the engine (dev-forge plugins) gets updated, the fuel (project's CLAUDE.md, rules, exemplars) might not take advantage of new capabilities. `/forge-keeper:optimize` does a full audit of project configuration against current engine features and proposes upgrades.

### How it differs from sync

| | forge-keeper:sync | forge-keeper:optimize |
|---|---|---|
| Trigger | Session changes / semantic drift | Plugin update / manual |
| Scope | Incremental — what this session added | Deep — full audit against current engine |
| Frequency | Per session | Per plugin update (~monthly) |
| Compares | Code changes vs existing CLAUDE.md | Project fuel vs engine capabilities |

### What it does

1. Detects current engine capabilities from forge-init's references
2. Audits project fuel: missing features, outdated patterns, deprecated config
3. Checks structural quality (line limits, frontmatter format, @imports)
4. Presents structured Upgrade/Restructure/Migrate proposal
5. Applies only what the user approves

### Proposal format

```
## Optimize Proposal

### Upgrade (adopt new capabilities)
- Create `docs/exemplars.md` — feature now available

### Restructure (improve existing configuration)
- `CLAUDE.md` — reorganize into WHY/WHAT/HOW structure

### Migrate (fix deprecated patterns)
- Update env vars: SK_ → FK_

### No changes needed
- `apps/api/CLAUDE.md` — follows current conventions ✓
```

### Design decision

Lives as `/forge-keeper:optimize` command (not a separate plugin) because forge-keeper is already permanently installed. Adding a command doesn't increase context footprint, and the deep restructuring is infrequent but shouldn't require install/uninstall ceremony.

---

## Future plugins

Each follows engine/fuel: procedures in the plugin, knowledge in the project.

- **ddd-scaffold** — Domain/bounded context boilerplate generation
- **nest-patterns** — NestJS module/service/controller conventions
- **test-guardian** — TDD/BDD workflow enforcement via hooks
- **deploy-checklist** — Pre-deployment verification skill
