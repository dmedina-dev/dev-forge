# Changelog

All notable changes to the dev-forge marketplace are documented here. Version bumps follow [docs/versioning.md](docs/versioning.md): a plugin or marketplace bump is a **cache invalidation event** for consumers, so an entry exists only when consumers should care.

> Format: each release lists plugin bumps as `name: old → new (level)` and breaking changes get a **Migration** block with explicit steps.

## v2.7.0 — 2026-05-17

Sharpens forge-ui-forge in two directions: a **precedence charter** that tells the agent how to weigh visual / behavior / data when the user pushes in conflicting directions, and a **canonical output-data-model reference** so downstream consumers (frontend-implementation agent, code generator, human reader) have a single contract for what Phase 5 hands off. Plus a small runtime polish on the dev server so overlay updates ship via plugin upgrade instead of per-project `refresh-assets.sh`.

**Plugins bumped:**
- `forge-ui-forge`: `0.5.0` → `0.6.0` (minor):
  - **Precedence charter** added to SKILL.md — 7 rules that crystallize the implicit hierarchy of ui-forge turns: workflow wins over speed, catalog before invention, schema is the data contract, behavior is authoritative for temporal logic, tokens are authoritative for visual primitives, pins are diffs not full restatements, brief defines scope. Each rule names the rebuttal it overrides (e.g. "andá ya", "queda mejor con #fafafa raw"), so Claude has explicit handles when user pressure pushes in those directions.
  - **Phase opening lock-in line** — at the start of each phase the agent posts a one-line summary of what was read (manifest / brief / schema / behavior / tokens / axis). The user intercepts misreads before generation happens, preventing the "12 variants generated against the wrong schema" failure mode.
  - **`references/output-data-model.md`** new — the canonical contract between ui-forge and any downstream consumer. Declares the three axes (visual / behavior / data), gives a TL;DR read order, the bundle map, exact schemas for every artifact (`config.json`, `brief.md`, `schema.json`, `mock.json`, scenarios, `behavior.md`, `screen-spec.md`, `decision.md`, `components-used.json`, `manifest.json`, `tokens.json`, fixtures, components), relationships between artifacts and which one is single source of truth for each fact, 7 invariants Phase 4 guarantees, versioning policy, and an explicit anti-features list.
  - **Plugin-served overlay** on the prototype dev server — `serve.sh` exports `UIFORGE_PLUGIN_DIR`; `serve.py` intercepts `GET /assets/overlay.js` and streams the plugin's current copy when that env points to a valid file. http:// consumers always get the freshest overlay shipped with the plugin install — no more `refresh-assets.sh` per project after a plugin upgrade. file:// keeps using the per-project bootstrap copy, so the offline fallback is unchanged.
  - **SKILL.md Phase 5 section** lists `output/decision.md` and `data/mock.json` + scenarios explicitly (they were implicit before) and links to the new output-data-model reference.

**Marketplace:** `2.6.0` → `2.7.0` (minor — mirrors highest plugin bump).

**Breaking changes:** none. `UIFORGE_PLUGIN_DIR` is purely opt-in (absence leaves the static handler path unchanged). The precedence charter is descriptive — Claude already operated this way most of the time; the charter just gives it explicit handles. The output-data-model reference adds no new artifacts; it documents the existing Phase 5 bundle shape.

---

## v2.6.0 — 2026-05-12

Curates two ideas from `mattpocock/skills` into existing dev-forge plugins instead of vendoring whole — a lightweight session handoff command in forge-keeper, and a deep enrichment of forge-ui-forge to capture **behavior/logic**, not just visual design. Plus a small post-tag patch (no version bump) swapping heart emojis (🩷🩵) for functional symbols (⚙️🔄) in the new ui-forge pin types.

**Plugins bumped:**
- `forge-keeper`: `1.3.1` → `1.4.0` (minor — new `/forge-keeper:handoff [optional focus]` command. Light counterpart to `/forge-keeper:sync`: writes a concise resumption note to `docs/sessions/YYYY-MM-DD-HHMM-handoff-<slug>.md` with goal / current state / open threads / next steps / skills to invoke / refs, without touching CLAUDE.md or rules. Idea curated from mattpocock/skills · `productivity/handoff` (MIT), adapted to land in dev-forge's session-log directory so `/forge-keeper:recall` finds handoffs too)
- `forge-ui-forge`: `0.4.0` → `0.5.0` (minor — behavior/logic capture):
  - **Anti-pattern "wallpaper variants"** added to SKILL.md — variants must disagree on structure (layout / hierarchy / primary affordance), not just colour or copy.
  - **Phase 1.5 optional** `data/behavior.md` skeleton for stateful screens (wizards, state machines, mutation-heavy). Inspired by mattpocock's `prototype/LOGIC.md` but adapted to ui-forge's HTML+Tailwind-only constraint (declarative markdown, no terminal TUI runtime).
  - **`screen-spec.md.tmpl`** extended with `## Behavior` section (State transitions · Business rules · Validations · Mutation contracts · Conditional rendering). Distilled in Phase 4 from pins + optional behavior.md.
  - **`variations.html.tmpl`** focus-mode added: full-size single variant with `←` / `→` keyboard navigation, `F` to toggle, `Esc` to exit. Coexists with the default grid scroll.
  - **`overlay.js`** gained 2 new pin types: `logic-rule` (⚙️ pink `#ec4899`) for business rules + per-field validations, `state-transition` (🔄 cyan `#06b6d4`) for temporal/sequential behaviors. Total now 7. `validation` was explicitly **not** added as a separate type because it's a subset of `logic-rule`; Phase 4 distillation splits them by heuristic.
  - **`decision.md.tmpl`** new — Phase 4 captures the *rationale*: winning variant + one-paragraph why + mix sources + one-line rejection per discarded variant.

**Marketplace:** `2.5.0` → `2.6.0` (minor — mirrors highest plugin bump).

**README:** new "Curated ideas adapted into other plugins" subsection in the mattpocock attribution block, documenting all 5 absorbed ideas so the inspiration trail is discoverable even when the code lives outside `forge-mattpocock`.

**Breaking changes:** none.

**Post-tag (commit `e556b35`, no version bump):** swapped heart emojis (🩷🩵) for functional symbols (⚙️🔄) in the forge-ui-forge pin types listing. Pink and cyan don't exist as Unicode circles, so hearts were the disambiguator; gears and cycles carry semantic weight beyond colour and don't introduce a casual tone in the skill description. Cosmetic only.

---

## v2.5.0 — 2026-05-11

Upstream sync sweep — applies obra/superpowers v5.0.7 → v5.1.0 (real content changes), refreshes the origin pins on the 6 anthropic-derived plugins (bookkeeping only — none of the 165 upstream commits touched vendored content), and fixes a latent zsh-glob bug in `/forge-commit:release` that aborted the slash command before reaching its task body.

**Plugins bumped:**
- `forge-superpowers`: `1.0.0` → `1.1.0` (minor — applied obra/superpowers v5.0.7 → v5.1.0. 10 skill files refreshed: worktree rewrites in `using-git-worktrees` and `finishing-a-development-branch`, the deleted upstream agent's persona absorbed into `requesting-code-review/code-reviewer.md`, plus updates to executing-plans, writing-plans, subagent-driven-development, systematic-debugging. 4 deprecated files deleted to mirror upstream removals: `commands/{brainstorm,execute-plan,write-plan}.md` and `agents/code-reviewer.md`. README refreshed. 6 new customization entries documenting the new excluded paths (`AGENTS.md`, `CLAUDE.md`, `assets/`, `scripts/sync-to-codex-plugin.sh`, `.version-bump.json`) and the canonical plugin.json rename)
- `forge-commit`: `1.1.1` → `1.1.2` (patch — fixed `/forge-commit:release` aborting with `(eval):1: no matches found: plugins/*/.claude-plugin/plugin.json` before reaching the task body. Cause: zsh `eval` rejects shell-glob expansion in slash-command `!`backtick`` context loaders even when files exist. Replaced the line-21 context loader and the step-5 verification block with `python3 -c "import glob; ..."` — single process, portable, side-steps zsh's `nomatch`)
- `forge-deep-review`: `2.0.0` → `2.0.1` (patch — bookkeeping: both origins refreshed to anthropics/claude-code `main @ fdfbc06`; 37 upstream commits since prior pin, 0 touched the vendored plugin paths)
- `forge-frontend-design`: `1.0.0` → `1.0.1` (patch — bookkeeping: origin commit refreshed to anthropics/claude-plugins-official `main @ fe8f813`; 128 upstream commits, 0 touched `plugins/frontend-design/`. Latent bug fixed: `origin.path` was `frontend-design` — should always have been `plugins/frontend-design` to match upstream layout)
- `forge-hookify`: `1.0.1` → `1.0.2` (patch — bookkeeping: commit pin refresh)
- `forge-mattpocock`: `1.0.0` → `1.0.1` (patch — review-only: 18 upstream commits inspected, kept local divergences. Upstream changes to `grill-with-docs/SKILL.md` and `to-prd/SKILL.md` are minor wording on top of the original upstream form, while our local customizations target a different documentation layout (docs/glossary.md, docs/plans/) — not absorbable without redoing the adaptation. 9 new customization entries documenting 6 excluded upstream skills with reasons)
- `forge-plugin-dev`: `1.0.0` → `1.0.1` (patch — bookkeeping: commit pin refresh)
- `forge-security`: `1.0.0` → `1.0.1` (patch — bookkeeping: commit pin refresh)

**Marketplace:** `2.4.0` → `2.5.0` (minor — driven by forge-superpowers minor).

**Breaking changes:** none for dev-forge consumers. **Upstream-driven removal** for users of legacy superpowers slash commands: `/brainstorm`, `/execute-plan`, `/write-plan` (deprecated stubs) and the standalone `superpowers:code-reviewer` named agent are gone. The skills themselves (`brainstorming`, `executing-plans`, `writing-plans`, `requesting-code-review`) remain and work as before — invoke them via the Skill tool or by name. Any in-house tooling that dispatched `Task (superpowers:code-reviewer)` should switch to `Task (general-purpose)` with the prompt template at `skills/requesting-code-review/code-reviewer.md`.

**Upstream pin state post-release:**
- `obra/superpowers`: `v5.1.0` (`f2cbfbe`)
- `anthropics/claude-code`: `main @ fdfbc06`
- `anthropics/claude-plugins-official`: `main @ fe8f813`
- `mattpocock/skills`: `main @ 9f2e0bd`

---

## v2.4.0 — 2026-05-06

Adds `forge-deepthink` — structured deep-thinking protocol triggered exclusively by the `/deepthink` slash command. Anti-trigger description by design so the skill never activates on natural-language phrases like "be brutally honest" or "razonamiento profundo".

**New plugin:**
- `forge-deepthink`: `0.1.0` — three-phase pipeline:
  1. Pre-filled 7-slot interview confirming context (problem, success criteria, constraints, etc.).
  2. Audit-ready response with sections 1-7: context confirmation, visible reasoning, confidence-tagged assumptions, recommendation in user-specified format, devil's-advocate red team, 6-month pre-mortem, take-home assumption audit with concrete weekly validation steps.
  3. Auto-compression checkpoints every ~5-6 turns once the protocol is active for the session.

Iterated through 2 rounds of subagent-based evals (4 test cases, 100% structural pass rate). Iter-2 added Tightness discipline (1-2 sentences max per slot), Section-7 dedup (label-reference + concrete weekly validation step), and reframed the why-this-exists toward **structure** (audit trail) over **honesty** (Claude already does that).

**Plugins bumped:** none beyond the new `forge-deepthink`.

**Marketplace:** `2.3.0` → `2.4.0` (minor — new plugin = new feature surface for consumers, not a fix). 17 → **18 plugins** total (14 working, 4 configuration).

**Docs:** README, CLAUDE.md tree, dependencies.md (section + matrix), `install-all.md` (regenerated via `scripts/generate-install-all.sh`) all in sync. `.gitignore` picks up `plugins/*-workspace/` so eval scratch space stays local.

**Breaking changes:** none.

---

## v2.3.0 — 2026-04-28

Adds `forge-mattpocock` — an alternative skills framework curated from mattpocock/skills (Matt Pocock, MIT). Coexists with `forge-superpowers`; no skill-name collisions.

**New plugin:**
- `forge-mattpocock`: `1.0.0` — 8 skills bundled:
  - `grill-me` · `grill-with-docs` — relentless interview to stress-test plans (the docs variant grills against the project's domain glossary / CLAUDE.md / `.claude/rules/` / `docs/adr/`)
  - `to-prd` — synthesize the current conversation into a wave-organized plan saved to `docs/plans/` (heavily adapted from upstream's GitHub-issue-tracker version)
  - `tdd` — red-green-refactor loop with deep-modules orientation
  - `diagnose` — disciplined diagnosis loop for hard bugs and perf regressions (reproduce → minimise → hypothesise → instrument → fix → regression-test)
  - `improve-codebase-architecture` — find deepening opportunities informed by `docs/glossary.md` and `docs/adr/`
  - `zoom-out` · `caveman` — small productivity helpers
  - 8 upstream skills explicitly excluded with per-skill reasons in `customizations.json` (personal/, deprecated/, misc/, setup-matt-pocock-skills, to-issues, qa, write-a-skill, triage)

**Plugins bumped:**
- `forge-init`: `1.1.0` → `1.1.1` (patch — `install-all.md` regenerated to include forge-mattpocock)

**Other:**
- `scripts/generate-install-all.sh` — fixed latent dependencies-shape bug (was reading `{required: [...]}` from the pre-v2.2.1 schema; now reads the flat array correctly so the forge-brainstorming dependency renders).
- README, CLAUDE.md, `docs/dependencies.md` updated to reflect the new plugin and Matt Pocock attribution.

**Marketplace:** `2.2.1` → `2.3.0` (minor — new plugin).

**Breaking changes:** none.

**Post-release docs sync** (commit `05a71c6`): `docs/dependencies.md` gained the missing forge-frontend-design and forge-ui-forge sections (pre-existing drift, not from this release); a new CLAUDE.md gotcha about schema-shape changes requiring an audit of every reader in `scripts/`; the canonical format for external-skill origin attribution pinned in `.claude/rules/plugin-authoring.md` as a single-line HTML comment after the YAML frontmatter.

---

## v2.2.1 — 2026-04-27

**Bugfix — marketplace was unreadable to Claude Code's `/plugin` UI.**

The `dependencies` field added to `forge-brainstorming` in v2.1.1 used the shape `{"required": [...]}` (object), assuming it was a dev-forge custom extension that unrecognising tooling would ignore. It is **not** an extension — `dependencies` is a reserved field in Claude Code's marketplace schema, and the validator expects a flat array of plugin name strings. Adding the marketplace via `/plugin marketplace add dmedina-dev/dev-forge` failed with:

```
Failed to parse marketplace file at .../marketplace.json:
Invalid schema: plugins.13.dependencies: Invalid input: expected array, received object
```

(Plugin index 13 = `forge-brainstorming` in the catalog order.)

**Fix:** rewrote the entry as `"dependencies": ["forge-superpowers"]`. Both the dependency-resolution semantics and the doc in `docs/dependencies.md` § "marketplace.json schema fields" updated.

**Plugins bumped:** none — the change is metadata in `marketplace.json`, no plugin's own contents changed.

**Marketplace:** `2.2.0` → `2.2.1` (patch — schema fix).

If you tried `/plugin marketplace add` against v2.2.0 and it failed, retry it now. If you hit a stale cached clone, remove it first:

```bash
rm -rf ~/.claude/plugins/marketplaces/*dev-forge*
```

Then `/plugin marketplace add dmedina-dev/dev-forge` will fetch the fixed v2.2.1 cleanly.

---

## v2.2.0 — 2026-04-27

Adds a reusable plugin-rename migration helper to `forge-init`.

**Plugins bumped:**
- `forge-init`: `1.0.3` → `1.1.0` (minor — new `/forge-init:migrate-from-forge` command + `scripts/migrate-from-forge.sh`)

**Marketplace:** `2.1.1` → `2.2.0` (mirrors forge-init).

### What it does

```
/forge-init:migrate-from-forge
```

A reusable helper for migrating a consumer's `~/.claude/settings.json` `enabledPlugins` map across a plugin rename. Currently scaffolded for a hypothetical `forge-* → df-*` rename:

1. Dry-runs first — shows which plugins are currently enabled, which will be renamed, and which will be dropped (plugins removed from the marketplace earlier).
2. After confirmation, rewrites `~/.claude/settings.json` (timestamped backup at `settings.json.bak.YYYYMMDDTHHMMSSZ`).
3. Updates `.claude/settings.local.json` if it has matching allowlist tokens.
4. Prints the slash-command block (`/plugin uninstall ...` + `/plugin install ...`) for the user to paste — `/plugin install` is interactive in Claude Code, so the file rewrite alone isn't enough; the cache also needs the new entries pulled.

### Status: template, not currently active

A real `forge-* → df-*` rename was prepared (and pushed as v3.0.0/v3.1.0) on 2026-04-27 then immediately reverted. The `df-*` target plugins do not exist in this marketplace. The script's hardcoded `RENAMES` and `REMOVED` maps still encode the abandoned rename — if you ever do a real plugin rename in this marketplace, edit those maps in `plugins/forge-init/scripts/migrate-from-forge.sh` first, then run the command.

### Rollback (if you do run it on real data)

The script never modifies in-place without backup:

```bash
cp ~/.claude/settings.json.bak.<timestamp> ~/.claude/settings.json
cp .claude/settings.local.json.bak.<timestamp> .claude/settings.local.json
```

**Breaking changes:** none.

---

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
