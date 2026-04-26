---
description: When running /forge-keeper:sync in dev-forge, validate marketplace docs are in sync with marketplace.json
globs: README.md, CLAUDE.md, .claude-plugin/marketplace.json, docs/dependencies.md
---

# Marketplace doc consistency on sync

When running `/forge-keeper:sync` in this repo, treat `marketplace.json` as the
canonical source of truth for the plugin catalog and validate that all
user-facing docs match it. Report mismatches as proposed updates and apply
only after explicit user approval (standard /sync flow).

## Validations to run

1. **Plugin count parity**: number of `**forge-*` rows in README plugin tables ==
   `jq '.plugins | length' .claude-plugin/marketplace.json`
2. **No stale references**: grep for plugin names in `README.md`, `CLAUDE.md`,
   `docs/dependencies.md`, `plugins/*/commands/*.md`, `plugins/*/skills/**/*.md`
   that no longer appear in `marketplace.json` — flag them as deletion or rename
   candidates. Exclude `docs/sessions/`, `docs/superpowers/plans/`, and
   `.upstream/` (historical artifacts).
3. **CLAUDE.md tree parity**: lines in the plugin tree (CLAUDE.md
   `## Architecture` section) == plugins in marketplace.
4. **dependencies.md matrix parity**: rows in `## Current plugin matrix` ==
   plugins in marketplace; each plugin in marketplace has a section in
   `## Current plugins`.
5. **Install commands**: `/plugin install forge-*` lines in README Quick Start
   should equal working plugins (= marketplace minus disposables:
   `forge-init`, `forge-plugin-dev`, `forge-context-mcp`, `forge-export`).
6. **install-all.md catalog**: `plugins/forge-init/commands/install-all.md`
   tables should list every working plugin from marketplace.

## When mismatches are found

Propose specific edits per mismatch:
- "README has N plugin rows, marketplace has M" → diff the lists, propose
  exact rows to add or remove.
- "Plugin X appears in CLAUDE.md tree but not marketplace.json" → propose
  removal from tree.
- "Plugin X is in marketplace but missing from install-all.md" → propose
  add row.
- "References to deleted plugin X found in plugins/<other>/SKILL.md:line" →
  propose targeted edit.

Apply only after explicit user approval (no autonomous edits).

## When sync is clean

Report: `Marketplace docs consistent with marketplace.json (N plugins).`
