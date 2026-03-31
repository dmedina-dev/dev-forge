---
name: forge-export
description: >
  Exports a dev-forge marketplace into a new standalone repository. Creates
  a personal or team marketplace with selected plugins pointing to their
  original sources. Use when you want to "export marketplace", "create new
  marketplace", "fork dev-forge", "new forge repo", "scaffold marketplace",
  "generate marketplace repo", "create team marketplace", "export plugins".
  Uninstall after use.
---

# Forge Export

Guided exporter: interviews you, then generates a new standalone marketplace repo.

## Step 1 — Name and destination

Ask the user:

1. Marketplace name (e.g., "acme-forge")
2. Short description (e.g., "Acme team's curated Claude Code plugins")
3. Destination path (absolute or relative, e.g., ~/acme-forge)
4. New marketplace repo URL (used for `source.url` entries in marketplace.json — a placeholder is fine)
5. Owner name and email (for authorship in generated files)

Validate the destination path does not already exist. If it does, stop and report — do not proceed.

## Step 2 — Detect plugins

Read `.claude-plugin/marketplace.json` in this repo. Classify each plugin as:

- **External** — has an `upstream` key (sourced from a third-party repo)
- **Native** — no `upstream` key (authored here)

For each plugin, check whether `plugins/<name>/.claude-plugin/customizations.json` exists and count
its `customizations` entries.

See `references/interview-guide.md` § Plugin classification.

## Step 3 — Select plugins

Present the detected plugins in a categorized table (external vs native) showing name, type, and
customizations count. Ask which to include. Default: all.

Validate dependencies — if forge-extended-dev is selected without forge-superpowers, warn and offer
to add forge-superpowers automatically.

See `references/interview-guide.md` § Plugin selection and § Dependency validation.

## Step 4 — Customizations per plugin

For each selected **external** plugin that has a `customizations.json`, present each customization
entry (id, type, target, summary) and ask which to carry over to the new marketplace.

See `references/interview-guide.md` § Customization interview.

## Step 5 — Native plugin treatment

For each selected **native** plugin, ask:

1. Copy content to the new repo? (yes / no)
2. If yes: capture authorship info for `origin` tracking in the generated `customizations.json`

See `references/interview-guide.md` § Native plugin interview.

## Step 6 — Settings and hooks

Detect entries in `.claude/settings.json` (hooks, permissions, env) that are associated with
selected plugins. Present them and ask which to export.

See `references/interview-guide.md` § Settings/hooks detection.

## Step 7 — Confirm and generate

Build the complete output plan in memory. Present a summary showing:

- Marketplace name and destination path
- Each plugin to be included: type, customizations carried over
- Full list of files that will be written
- Native plugins that will have their content copied

**DO NOT write files until the user explicitly confirms.**

See `references/output-schema.md` for all generated file shapes.

## Step 8 — Write output

On confirmation, generate the new marketplace:

1. Create the destination directory structure
2. Write top-level files: `marketplace.json`, `CLAUDE.md`, `README.md`, `docs/dependencies.md`,
   `commands/install-all.md`
3. For each selected external plugin: write `plugins/<name>/.claude-plugin/customizations.json`
   with only the carried customizations
4. For each selected native plugin copied: copy the plugin directory and write a
   `customizations.json` recording origin and authorship
5. Write `.claude/settings.json` with the selected hooks/settings
6. Run `git init` and create an initial commit

Post-write: print a summary of what was generated, then display the uninstall reminder:

```
To uninstall forge-export (no longer needed):
  /plugin → Manage and uninstall plugins → forge-export → Uninstall
```

See `references/output-schema.md` § Generation rules.

## References

- Interview logic → `references/interview-guide.md`
- Output schemas and generation rules → `references/output-schema.md`
