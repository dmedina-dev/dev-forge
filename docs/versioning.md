# Versioning policy

This document defines when and how to bump versions in dev-forge — for individual plugins (`plugins/<name>/.claude-plugin/plugin.json`) and for the marketplace as a whole (`.claude-plugin/marketplace.json` `metadata.version`).

The goal is **consumer cache predictability**: a version bump invalidates the consumer's plugin cache, so we want bumps to happen when behavior actually changes — not when a typo got fixed in a comment.

## Plugin version (semver)

Each plugin uses semver: `MAJOR.MINOR.PATCH`.

### MAJOR (breaking)
Bump when consumers will need to take action to keep things working:
- A command, skill, agent, or hook is **renamed** or **removed**.
- A skill's trigger phrases change in a way that breaks existing prompts.
- A hook's behavior changes such that previous configurations stop working.
- A plugin gains a hard dependency it didn't previously have.
- The on-disk layout under `<project>/.<plugin>/` changes incompatibly.

After a major bump, the matching CHANGELOG entry MUST list the migration steps.

### MINOR (additive)
Bump when something **new** ships and existing usage still works:
- New command / skill / agent / hook / subcommand.
- New configuration option (with a default that preserves old behavior).
- Significantly expanded scope of an existing skill.

### PATCH (fixes)
Bump only for bugs or surface refinements that are observable to the user:
- Bug fix in a hook script, agent prompt, or command.
- Trigger phrase tweak that fixes false negatives in skill activation.
- Description text in plugin.json that materially changes how the plugin advertises itself.

### When NOT to bump
Don't bump for:
- Pure doc edits (`.md` typos, formatting, internal comments) — but see the carve-out below.
- Test-only changes.
- Refactors that produce identical observable behavior.

**Carve-out:** if doc edits change a SKILL.md `description` (the trigger field), that's a behavior change — the skill will now activate on different prompts. That counts as PATCH at minimum, MINOR if the change is large.

## Marketplace version

The top-level `metadata.version` in `marketplace.json` is the **release identifier** consumers see.

### MAJOR
Bump when at least one of:
- A plugin is **removed** from the marketplace.
- A plugin is **renamed** (which is "remove old + add new" from the consumer's perspective — their cache for the old name will go stale).
- A breaking change ripples across multiple plugins.

History: `1.x → 2.0.0` happened on 2026-04-26 when `forge-executor`, `forge-ui-expert`, and `forge-ralph` were removed and `forge-extended-dev` was renamed to `forge-deep-review`.

### MINOR
Bump when at least one plugin had a MINOR or MAJOR bump.

### PATCH
Bump when only patches landed across one or more plugins.

### Rule of thumb
> The marketplace version mirrors the **highest** plugin bump in the release.

So if release N has one minor (`forge-x` 0.3 → 0.4) and three patches, marketplace bumps minor (`2.0.0 → 2.1.0`). If release N has only patches, marketplace bumps patch (`2.1.0 → 2.1.1`).

## Release process

Releases happen via `/forge-commit:release`. The skill detects which plugin directories changed since the last git tag and prompts for bumps.

1. Commit work as feature branches; merge to main.
2. Run `/forge-commit:release` — it bumps and tags.
3. Update `CHANGELOG.md` with the release notes (the release commit links to it).
4. Push tag.

## CHANGELOG discipline

Every release MUST have a `CHANGELOG.md` entry under a heading `## v{X.Y.Z} — {YYYY-MM-DD}`.

For each plugin that bumped, list:
- Old version → new version (level: major / minor / patch)
- One-line summary of the change
- Migration steps if the bump is major

The same entry should also call out marketplace-level changes (added/removed plugins, renames, schema changes to `marketplace.json`).

## Update-check cadence

We vendor plugins from upstream sources (see `customizations-pattern.md`). Upstream may ship security or behavior fixes that affect us. To keep this from drifting:

- **Manual:** run `/forge-keeper:update-check` at least every 14 days.
- **Automated** (planned, tracked in CHANGELOG once shipped): a scheduled GitHub Action / cron-style routine to run the check weekly and open a PR when updates exist.

The `last_checked` field in each `customizations.json` is the audit trail. If `last_checked` is more than 30 days old when a release ships, mention it in the release notes so consumers know what's stale.
