# Marketplace hardening + aborted rename — 2026-04-27

Long session covering five tagged releases and one force-pushed undo. The thread is **release-pipeline maturity**: catch the kinds of mistakes that break consumers without you noticing until they try to install.

## Timeline

1. **v2.1.0** — forge-ui-forge live mode (live overlay proxy that injects the annotation overlay into an existing dev server's HTML responses). Eight TDD waves, 42 aiohttp-driven tests, single squashed commit. Captured in `docs/superpowers/plans/2026-04-27-ui-forge-live-overlay-proxy.md`.
2. **Audit** — dispatched `claude-code-guide` agent to red-team the repo against "what hurts users between releases". Top three findings: no CHANGELOG, inconsistent version-bump policy (doc-only edits triggering cache invalidation), no machine-readable enforcement of the `forge-brainstorming → forge-superpowers` hard dependency.
3. **v2.1.1** — release-pipeline hardening from the audit:
   - `CHANGELOG.md` with retroactive coverage of v2.0.0 (the prune that never got a tag) + v2.1.0.
   - `docs/versioning.md` — explicit semver policy per plugin and for marketplace metadata.version. Doc-only changes are NOT a patch bump unless the SKILL.md description (which controls trigger behavior) changed.
   - `marketplace.json` schema extensions: `dependencies.required` (object form) and `writes_outside_project_root`. **THIS WAS THE BUG.**
   - `scripts/generate-install-all.sh` — auto-regenerates `plugins/forge-init/commands/install-all.md` from the catalog. Errors loud if any plugin lacks a `SHORT_LABELS` entry.
   - README "Upgrading" section pointing at the changelog, `/reload-plugins`, and version pinning notes.
4. **v2.2.0** — `/forge-init:migrate-from-forge` recipe + bash script for migrating consumer settings.json across plugin renames (rewrites `enabledPlugins` keys with timestamped backup, drops removed plugins, prints the slash-command block to paste).
5. **v3.0.0 + v3.1.0 (aborted)** — rename `forge-X → df-X` because "forge" was redundant with the `dev-forge` marketplace name. Renamed 16 plugin directories, 4 skill subdirectories, 84 files content-rewritten via Python helper, 2153 net additions in a single squashed commit. Tagged, pushed, then user reconsidered. Force-push back to v2.1.1 + delete remote tags v3.0.0 v3.1.0 + restore user's settings.json from backup + clear `df-init` from cache. The migration scripts were preserved as a template (under forge-init), released as v2.2.0.
6. **v2.2.1 (bugfix)** — the `dependencies: {"required": [...]}` shape from v2.1.1 broke `/plugin marketplace add` for every consumer with `Invalid input: expected array, received object`. `dependencies` is a **reserved field** in Claude Code's marketplace schema, expected as a flat array of plugin name strings. Rewrote to `["forge-superpowers"]`. The bug was undetected on the maintainer's machine (the marketplace was already cached pre-bug); discovered by attempting `/plugin marketplace add` on a second machine. v2.1.1 sat broken for ~5 hours.
7. **Health check** — `scripts/marketplace-health.sh` covering 6 groups of checks. Verified by injecting the v2.1.1 regression and confirming the script catches it. CLAUDE.md gotcha and `.claude/rules/plugin-authoring.md` updated to reference it as the canonical pre-push check.

## Lessons

### `python3 -m json.tool` is not schema validation

The whole audit-driven hardening and a CHANGELOG entry justifying every bump did not catch the bug. The marketplace.json was syntactically valid JSON; the failure was structural. **Need a real schema check before push** — `marketplace-health.sh` is now that.

### Don't invent fields on top of names you don't own

I named the new field `dependencies` thinking I was extending an open schema. Claude Code already uses that exact name with a strict shape. The lesson: any marketplace.json field that overlaps with a name Claude Code might be using needs verification against an actual `/plugin marketplace add` end-to-end. Custom extensions are safer when their names are obviously dev-forge-specific (e.g. `writes_outside_project_root`, which Claude Code ignores cleanly).

### Force-push protocol when only the maintainer has consumed

v3.0.0/v3.1.0 were public for ~30 minutes before the user said "let's not". Plan for the undo:

1. `git reset --hard <prev-tag>` — local main back.
2. Re-apply anything worth keeping (the migration scripts) on a feature branch off the reset.
3. New tag (v2.2.0).
4. `git push --force-with-lease origin main`.
5. `git push --delete origin <bad-tag-1> <bad-tag-2>`.
6. `git tag -d <bad-tag-1> <bad-tag-2>` locally.
7. Restore consumer state on the maintainer's own machine: `~/.claude/settings.json` from timestamped backup, `rm -rf ~/.claude/plugins/cache/<marketplace>/<aborted-plugin>/`.

Acceptable because the user is the sole consumer. NOT acceptable on a marketplace with external installs.

### Zombies in consumer state after a marketplace prune

When a plugin is removed from `marketplace.json`, the consumer's:
- `~/.claude/plugins/cache/<marketplace>/<old-plugin>/` survives (cache is not cleaned on marketplace update)
- `~/.claude/settings.json` `enabledPlugins` survives
- `/plugin` UI **still shows the orphaned plugin** as installed-not-in-catalog

`/plugin uninstall <name>` would clean them, but only if the user knows to do so. The migration helper at `plugins/forge-init/scripts/migrate-from-forge.sh` is the recovery path: it can detect zombies via `enabledPlugins` keys missing from the current catalog and produce the cleanup block. Pattern is reusable for any future prune.

### The marketplace clone in the consumer is at `~/.claude/plugins/marketplaces/<owner>-<repo>/`

Slash → dash naming. It is a real `git clone` — `cd ~/.claude/plugins/marketplaces/<owner>-<repo> && git pull` refreshes catalog manually if `/plugin marketplace update` does not pick up changes (or cannot be invoked from where you are). For maintainers iterating on their own marketplace and seeing stale state on a consumer machine, this is the manual fallback.

## Files touched (repo-level)

```
CHANGELOG.md                                              (created)
docs/versioning.md                                        (created)
docs/dependencies.md                                      (schema docs updated 2x)
README.md                                                 (Upgrading section)
.claude/rules/plugin-authoring.md                         (marketplace-health rule)
.claude/rules/sync-keeps-docs-current.md                  (no change)
CLAUDE.md                                                 (one new gotcha)
scripts/generate-install-all.sh                           (created)
scripts/marketplace-health.sh                             (created)
plugins/forge-init/commands/install-all.md                (regenerated)
plugins/forge-init/commands/migrate-from-forge.md         (created)
plugins/forge-init/scripts/migrate-from-forge.sh          (created)
.claude-plugin/marketplace.json                           (heavily edited; ended at v2.2.1)
plugins/forge-{init,export,keeper,profiles,brainstorming}/.claude-plugin/plugin.json   (versions bumped)
plugins/forge-ui-forge/{skills,tests,...}                 (live mode)
.gitignore                                                (.venv-dev, __pycache__, .pytest_cache)
```

## Releases

| Tag | When | Change |
|---|---|---|
| v2.1.0 | 2026-04-27 ~07:41 | live overlay proxy mode in forge-ui-forge |
| v2.1.1 | 2026-04-27 (after audit) | release-pipeline hardening |
| v2.2.0 | 2026-04-27 | migrate-from-forge helper as template |
| v3.0.0 | abandoned | rename forge-X → df-X (force-pushed away) |
| v3.1.0 | abandoned | migrate command (force-pushed away) |
| v2.2.1 | 2026-04-27 | dependencies field shape fix |

## Open follow-ups

- Wire `marketplace-health.sh` into `/forge-commit:release` so a release that fails health cannot tag. Five-line change in `release.md`.
- Schedule weekly `/forge-keeper:update-check` so vendored plugins (forge-superpowers, forge-deep-review, ...) don't drift more than 14 days.
- Test coverage: 14 of 16 plugins still have zero automated tests. forge-ui-forge has 42. Consider a smoke-test harness per plugin (one representative command).
- The audit recommended a `/plugin update` command surface in the README — partially done in the Upgrading section, but a dedicated reference page might help if external consumers grow.
