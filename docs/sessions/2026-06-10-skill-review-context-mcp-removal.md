# Skill review (39 skills) + forge-context-mcp removal

**Date:** 2026-06-09/10
**Branch:** `fable-cuarte` (pending release → must be **v3.0.0**, breaking: plugin removal)

## What happened

### 1. Multi-agent skill review (workflow, 58 agents)
One reviewer per skill (39) + 4 cross-cutting auditors (trigger collisions, conventions,
duplication, docs parity) + adversarial verification per plugin. 131 raw findings → **86 confirmed**
(45 refuted): 13 high · 45 medium · 28 low. Full report: `.tmp/skill-review-2026-06-09.md`
(gitignored artifact). Remaining work organized in waves: `docs/plans/2026-06-10-skill-review-fixes.md`.

### 2. forge-profiles fix (applied)
Docs named dead keys: SKILL.md/commands said switch updates a `plugins` array + `mcpServers` in
settings.local.json. Reality (verified against the maintainer's working installs): Claude Code reads
`enabledPlugins` (object, `"plugin@marketplace": true`), and MCP servers live in `.mcp.json`.
Switching *worked* only because the executing agent improvised past the doc. Also: stored
`options.profiles` can be a JSON-encoded string (legacy) — read steps now tolerate it. Storage under
`pluginConfigs` was correct all along and is untouched. Initial review overcalled this as "core
mechanism broken"; user pushback + verification narrowed it to doc-reality mismatch.

### 3. forge-context-mcp DELETED (18 → 17 plugins)
Review proved the content hallucinated: all 3 cited GitHub repos 404, `serena-mcp` PyPI package
doesn't exist (real: `oraios/serena`), `xray-mcp` npm is an unrelated Jira product, and it taught
MCP config in `.claude/settings.json`, which Claude Code doesn't read. User decision: delete rather
than fix. Cleaned 9 reference sites (marketplace.json, README, CLAUDE.md tree, dependencies.md
section+matrix, sync rule disposables list, migrate-from-forge.sh, generate-install-all.sh,
regenerated install-all.md). `marketplace-health.sh` green. Successor concept: **forge-memory**
(new plugin, future design — a reformulation, not a fix).

### 4. forge-ui-forge description fix (applied)
Frontmatter description was 1987 chars; the harness truncates at 1024 — every explicit trigger
phrase (including all Spanish ones) sat past the cutoff and never worked. Compressed to 969 chars
as a `>-` folded scalar (also fixes strict-YAML failure from unquoted `: ` in a plain scalar).
New rule added to `.claude/rules/plugin-authoring.md` (≤1024 chars + folded scalar + validation
one-liner).

## Key learnings

- **Description length is a silent trigger killer**: nothing warns when a SKILL.md description
  blows the 1024 budget; the skill just stops matching the phrases past the cutoff.
- **Adversarial verification earns its cost**: 45/131 findings (34%) were refuted by the verify
  pass — including plausible-sounding ones that would have wasted fix effort.
- **"Tested and works" can mask doc rot**: forge-profiles functioned because agents adapt to the
  real file, not the documented one. Doc-reality mismatches in agent-executed instructions are
  latent failures, not cosmetic issues.

## Pending

- Waves 1-5 in `docs/plans/2026-06-10-skill-review-fixes.md` (native quick wins → repo docs parity
  → vendored batches with customizations.json entries → attribution backfill → v3.0.0 release).
- forge-memory design (user).
- stock-manager's stored profiles reference deleted plugins (`forge-context-mcp@dev-forge`,
  `forge-extended-dev@dev-forge`, `forge-ui-expert@dev-forge`) — recreate profiles when switching.
