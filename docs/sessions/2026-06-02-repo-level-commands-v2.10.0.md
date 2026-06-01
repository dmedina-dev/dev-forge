# Repo-level maintenance commands + `/import-plugin` (v2.10.0)

**Date:** 2026-06-02
**Tag:** v2.10.0 (`783c5d9`) · feature commit `2cf6d58`

## What happened

Started as a routine `/update-check`, ended as a structural refactor + release.

### 1. Update-check sweep
Checked all 8 external plugins. Only two had real upstream changes (most repo tips advanced but
their tracked subpaths didn't move):
- **forge-security** — upstream `security-guidance` had a major rewrite (LLM-assisted review:
  `_base.py`, `llm.py`, `review_api.py`). ⚠ 1 conflict with `custom-02`. **Not applied** — left for a deliberate decision.
- **forge-mattpocock** — one vendored skill changed (`to-prd/SKILL.md`). **Not applied.**

### 2. Migrated 2 commands plugin → repo-level `.claude/commands/`
Rationale: both only ever functioned *inside* the dev-forge repo (one scans
`plugins/*/.claude-plugin/customizations.json`, the other guards on `marketplace.json`), so shipping
them inside installable plugins was misleading.
- `forge-keeper:update-check` → `/update-check` (guide moved via `git mv` to `.claude/commands/references/`)
- `forge-commit:release` → `/release` (dropped `custom-02` + the `/release` mention from forge-commit)

### 3. New `/import-plugin` (repo-level)
Inverse of the `forge-export` plugin. Adopts a plugin **into** the marketplace from two sources:
- **installed** — reads `~/.claude/plugins/installed_plugins.json` (actually-installed set, not the
  full marketplace catalogs — the first loader draft enumerated 200+ aggregator entries, wrong),
  files from the cache `installPath`, true upstream recovered from the source marketplace's own `marketplace.json`.
- **remote git** — clones into `.upstream/`.

Writes `customizations.json` (github or native origin), registers in `marketplace.json`, regenerates
`install-all.md`, validates with `marketplace-health.sh`. Does NOT bump versions (that's `/release`).

### 4. Release v2.10.0 — with a collision
Planned **v2.9.0** (forge-keeper 1.4.1→1.5.0, forge-commit 1.1.3→1.2.0, both minor for command
removal — minor not major because the commands were no-ops for external consumers). On push, found
the remote had already shipped **v2.8.1** (forge-profiles install hotfix) and **v2.9.0**
(forge-ui-forge subagents) from another machine. Rebased onto `origin/main`, resolved conflicts in
`plugin-authoring.md` (kept both rules) and `CHANGELOG.md` (reordered), **renumbered to v2.10.0**,
re-tagged, pushed.

## Decisions
- Maintenance commands belong in repo-level `.claude/commands/`, not plugins. Captured as a CLAUDE.md gotcha.
- Command removal from a plugin = **minor** bump when the command never worked for external consumers (vs. the major-for-removing-plugins rule).
- Concurrent-release recovery = rebase + renumber, never merge. Now documented in `docs/versioning.md` § Concurrent releases.

## Follow-ups
- **forge-security** upstream rewrite still pending — decide whether to adopt the LLM-review version (resolve the `custom-02` conflict) or stay on the reminder-only hook.
- **forge-mattpocock** `to-prd/SKILL.md` upstream update still pending.
- `/import-plugin` is untested end-to-end (loaders smoke-tested, full flow not yet run).
