# Changelog

All notable changes to the dev-forge marketplace are documented here. Version bumps follow [docs/versioning.md](docs/versioning.md): a plugin or marketplace bump is a **cache invalidation event** for consumers, so an entry exists only when consumers should care.

> Format: each release lists plugin bumps as `name: old → new (level)` and breaking changes get a **Migration** block with explicit steps.

## v2.1.1 — 2026-04-27

Release-pipeline hardening from a marketplace audit. Pure docs + tooling — no plugin behavior changed.

**Plugins bumped:**
- `forge-init`: `1.0.2` → `1.0.3` (patch — `install-all.md` regenerated from `marketplace.json` and now reflects forge-ui-forge's live mode in its description; ordering rebuilt with hard-deps-first)

**Marketplace:** `2.1.0` → `2.1.1` (patch — mirrors forge-init).

**New repo-level files:**
- [`CHANGELOG.md`](CHANGELOG.md) — this file.
- [`docs/versioning.md`](docs/versioning.md) — semver policy for plugins and the marketplace, plus update-check cadence.
- [`scripts/generate-install-all.sh`](scripts/generate-install-all.sh) — regenerates `plugins/forge-init/commands/install-all.md` from `marketplace.json` so the install plan never diverges from the catalog. Idempotent. Errors loud if a plugin lacks a short-label entry.

**`marketplace.json` schema additions** (additive, no migration needed):
- `dependencies.required` — array of plugin names that must be installed alongside this plugin. Currently set on `forge-brainstorming → forge-superpowers`.
- `writes_outside_project_root` — array of paths a plugin owns outside the consumer's project root. Currently set on `forge-telegram → ~/.claude/channels/telegram/`.

Both fields are documented in `docs/dependencies.md` "marketplace.json schema extensions". Tooling that doesn't recognize them ignores them.

**Doc adds:**
- README gains an "Upgrading" section with concrete steps for cache refresh, breaking-change migration, and version pinning.

**Breaking changes:** none.

---

## v2.1.0 — 2026-04-27

Headline: forge-ui-forge gains a "live mode" — a reverse proxy that injects the annotation overlay into an existing dev server's HTML responses, so any running app (Vite / Next / Rails / Django / …) can be annotated without source changes.

**Plugins bumped:**
- `forge-ui-forge`: `0.3.0` → `0.4.0` (minor — live overlay proxy mode, new subcommands `live` / `stop-live` / `status-live`, optional `aiohttp` dependency)
- `forge-brainstorming`: `1.0.0` → `1.0.1` (patch — SKILL.md description sync)
- `forge-export`: `1.1.1` → `1.1.2` (patch — interview-guide and output-schema doc cleanup)
- `forge-init`: `1.0.1` → `1.0.2` (patch — `install-all.md` synced with the pruned catalog)
- `forge-keeper`: `1.3.0` → `1.3.1` (patch — `update-check-guide` refresh)
- `forge-profiles`: `1.1.0` → `1.1.1` (patch — `profile-change` doc tweak)

**Marketplace:** `2.0.0` → `2.1.0` (minor — mirrors highest plugin bump).

**Breaking changes:** none.

**New consumer-visible:**
- `bash live.sh --target http://localhost:3000` starts the live proxy; install `aiohttp` first (`pip install aiohttp`) — the prototype mode keeps working without it.
- `show-pin-live.py <session-id> --round N` reads pins from a live session.

---

## v2.0.0 — 2026-04-26

> This release was tagged retroactively in CHANGELOG only — git did not get a `v2.0.0` tag at the time. Consumers upgrading from `v1.17.0` saw the changes below bundled into the next pull they did. The migration steps below are what you need if you still have any of the removed/renamed plugins installed.

**BREAKING — three plugins removed:**
- `forge-executor` — removed. Multi-wave plan executor was tightly coupled to agents (`BackendImplementer`, `FrontendImplementer`, etc.) that were referenced but never registered, so the orchestrator failed at first dispatch. Replaced by **`forge-superpowers:executing-plans`** (inline) or **`forge-superpowers:subagent-driven-development`** (subagent-per-task with review).
- `forge-ui-expert` — removed. Catalog-style UI expert never replaced the prototype/forge flow that `forge-ui-forge` already provides. No replacement; use `forge-ui-forge` for prototyping or `forge-frontend-design` for stack-specific UI.
- `forge-ralph` — removed. Experimental and unmaintained; no replacement.

**BREAKING — plugin renamed and re-scoped:**
- `forge-extended-dev` → **`forge-deep-review`** (`2.0.0`). The plugin was trimmed to focus exclusively on review (5 specialized agents: tests, errors, types, comments, simplification) plus the automated PR review command. Feature-development and TDD-execution responsibilities moved to `forge-superpowers` and `forge-brainstorming`.

**Marketplace:** `1.17.0` → `2.0.0` (major — plugin removals + rename).

### Migration

If you had any of the removed plugins installed, your cache contains stale entries. Run:

```
/plugin uninstall forge-executor
/plugin uninstall forge-ui-expert
/plugin uninstall forge-ralph
/plugin uninstall forge-extended-dev    # if installed
```

Then install the replacements:

```
/plugin install forge-superpowers       # if you used forge-executor
/plugin install forge-deep-review       # replaces forge-extended-dev
```

Workflow swaps:
- `/forge-executor:execute-plan <plan>` → `/forge-superpowers:executing-plans <plan>` (inline) or hand the plan to `/forge-superpowers:subagent-driven-development` (subagent-per-task with review checkpoints).
- `/forge-extended-dev:deep-review` → `/forge-deep-review:deep-review` (same agents, new command path).
- `/forge-extended-dev:pr-review` → `/forge-deep-review:pr-review`.
- `/forge-extended-dev:feature-dev` → `/forge-superpowers:brainstorming` (discovery + planning) followed by `/forge-superpowers:test-driven-development` (execution).

---

## v1.17.0 and earlier

Pre-CHANGELOG era. See `git log v1.17.0` and tag history (`git tag -l 'v1.*'`) for context. The most useful artifacts from before this changelog existed:

- **Marketplace pruning rationale**: `docs/sessions/2026-04-26-marketplace-pruning-v2.md` documents why `forge-executor`, `forge-ui-expert`, and `forge-ralph` were removed and which sub-agents and skills they referenced that were never registered.
- **Customizations pattern**: `docs/customizations-pattern.md` describes how externally-vendored plugins (forge-superpowers, forge-deep-review) track upstream and apply local modifications. Was finalized in the v1.16.x line.

Future releases will be documented here at release time, not retroactively.
