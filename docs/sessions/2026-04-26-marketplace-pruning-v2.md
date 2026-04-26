## Session: 2026-04-26 — Marketplace pruning v2.0.0 (19 → 16 plugins)

### Changes made

- **Deleted plugins** (3):
  - `forge-executor` — broken: orchestrator dispatched non-existent
    `subagent_type` strings (BackendImplementer, FrontendImplementer,
    Configurator, InfraArchitect, Reviewer, Analyst). Smoke-tested
    via direct `Agent({subagent_type: "BackendImplementer"})` →
    `Agent type 'X' not found`. Duplicates `superpowers:executing-plans`.
  - `forge-ui-expert` — 221 files, 8.2 MB, 7 competing auto-trigger
    skills. Same UI scope as forge-frontend-design (3 files, 16K).
  - `forge-ralph` — niche persistent loop technique. Harness `/loop`
    skill covers the use case generically.
- **Renamed**: `forge-extended-dev` → `forge-deep-review`, scoped to review
  agents + `/pr-review`. Dropped Phase A (`/feature-dev`,
  `code-architect`, `code-explorer`) since `superpowers:brainstorming` +
  `superpowers:writing-plans` cover discovery and architecture design.
- **Bumped**: `marketplace.json` v1.17.0 → v2.0.0 (breaking change).
- **Rewrote**: forge-ui-forge README description (10 lines → 2).
- **Filled gaps in install-all.md**: added forge-brainstorming,
  forge-profiles, forge-telegram, forge-proactive-qa, forge-ui-forge,
  forge-context-mcp, forge-export (were missing pre-prune).
- **Cleaned**: `.upstream/nextlevelbuilder-ui-ux-pro-max-skill/` (-16M)
  since forge-ui-expert was the only consumer.

### Decisions taken

- **`.ui-forge/` directory name kept unchanged** despite considering
  rename. Rationale: zero breaking change for projects with existing
  registries. Plugin rename to `forge-ui` was discussed and reverted —
  `forge-ui-forge` aligns with skill name (`ui-forge`), directory
  (`.ui-forge/`), and subcommand prefix (`/ui-forge serve|stop|status|refresh`).
- **forge-frontend-design kept over forge-ui-expert** based on weight:
  3 vs 221 files, 16K vs 8.2M, 1 vs 7 competing skills. Same UI scope.
- **forge-deep-review no longer "requires forge-superpowers"**. The
  surviving review agents are independent. Only `forge-brainstorming`
  has a hard dependency now.
- **Single branch `prune/simplify-marketplace`** with 3 logical commits
  (docs sync / rename / deletes) over 4 branches per delete. Cleaner
  for a single-user marketplace with no parallel contributors.

### Context for next session

- Branch `prune/simplify-marketplace` is **local only**. Pending
  decision: push + PR vs direct merge to `main`.
- **Plugin versions not bumped** via `/forge-commit:release`. Only
  `forge-deep-review` was bumped manually to v2.0.0 (since it's a
  rename + scope reduction). Other touched plugins (forge-keeper,
  forge-export, forge-init, forge-profiles, forge-brainstorming) are
  still at their pre-prune versions.
- **Optional global tag `v2.0.0`** of the repo not created — could mark
  the "great pruning" in history if desired.
- Auto-memory `project_devforge.md` updated to reflect v2.0.0 and
  16-plugin inventory.

### Files touched

- `.claude-plugin/marketplace.json` (v2.0.0, 16 plugins)
- `README.md`, `CLAUDE.md`, `docs/dependencies.md`
- `plugins/forge-init/commands/install-all.md`
- `plugins/forge-export/skills/forge-export/{SKILL.md, references/interview-guide.md, references/output-schema.md}`
- `plugins/forge-keeper/{commands/update-check.md, skills/forge-keeper/references/update-check-guide.md}`
- `plugins/forge-profiles/commands/profile-change.md`
- `plugins/forge-brainstorming/skills/brainstorming-workflow/{SKILL.md, references/review-lenses.md}`
- `plugins/forge-deep-review/` (renamed from forge-extended-dev, trimmed)
- New: `.claude/rules/sync-keeps-docs-current.md`
- New: this session log
