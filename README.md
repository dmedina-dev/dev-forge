# Dev Forge

Personal unified plugin for Claude Code. One plugin, all your skills.

## The idea

Instead of installing superpowers + skill-creator + custom plugins in every project,
dev-forge curates everything in one place. Install once, get everything. Update here,
all projects benefit.

**Engine/Fuel separation still applies**: dev-forge provides procedures (engine).
Each project provides its own knowledge (fuel) — CLAUDE.md, `.claude/rules/`,
`docs/sessions/`, ADRs. Created by forge-init, maintained by forge-keeper.

## Plugins

| Plugin | What it does | Lifecycle |
|--------|-------------|-----------|
| **forge-keeper** | All curated skills + context maintenance + hooks | Permanent — your daily driver |
| **forge-init** | Bootstraps new projects with conventions | Disposable — uninstall after use |

### forge-keeper (the main plugin)

Contains everything you use daily:

**Context maintenance:**
- `/forge-keeper:sync` — Capture session changes into CLAUDE.md, rules, exemplars
- `/forge-keeper:status` — Context health report with drift detection
- `/forge-keeper:optimize` — Deep restructuring after plugin updates

**Curated skills** (from superpowers, anthropic, custom):
- Brainstorming, TDD, debugging, code review, planning — personalized versions
- skill-creator from anthropic official
- Custom skills as needed

**Hooks:**
- Context watcher — safety net for drift detection

### forge-init (bootstrapper)

Run `/forge-init:init` in a new project:
1. Runs native `/init` interview
2. Layers conventions: CLAUDE.md quality, per-directory context, rules, docs scaffolding, code exemplars
3. Uninstall after use

## Installation

```bash
# Add marketplace (once per machine)
/plugin marketplace add dmedina-dev/dev-forge

# In any project
/plugin install forge-keeper    # permanent
/plugin install forge-init      # for new projects only
```

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `FK_MIN_FILES` | 20 | Changed files before hook reminder |
| `FK_MIN_ZONES` | 3 | Zones touched before hook reminder |
| `FK_COOLDOWN` | 15 | Prompts between reminders |

## Curating skills

```bash
# 1. Add skill to forge-keeper
plugins/forge-keeper/skills/<name>/SKILL.md

# 2. Test locally
claude --plugin-dir plugins/forge-keeper

# 3. Push — all projects get the update
git push
```

Skills from external sources note their origin at the top of SKILL.md.
Personal adaptations are documented inline.

## License

MIT
