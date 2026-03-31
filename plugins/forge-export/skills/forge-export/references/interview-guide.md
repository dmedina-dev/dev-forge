# Interview Guide — forge-export Steps 2–6

Reference for detecting plugin metadata and conducting the interview before
generating the new marketplace. Claude reads this guide when reaching Step 2
of the export flow.

---

## § Plugin classification

Every entry in `.claude-plugin/marketplace.json` is either **external** or **native**.

### How to identify external plugins

An entry is external if it has an `upstream` key at the top level. The value
can be a single object or an array of objects — both count.

```json
{ "name": "forge-superpowers", "upstream": { "repo": "obra/superpowers", ... } }
{ "name": "forge-extended-dev", "upstream": [ { "repo": "..." }, { "repo": "..." } ] }
```

### How to identify native plugins

An entry is native if it has NO `upstream` key. The `source.url` points to
the same dev-forge repository.

```json
{ "name": "forge-init", "source": { "url": "https://github.com/dmedina-dev/dev-forge.git", ... } }
```

### Customization count per plugin

For each plugin (external or native), resolve its directory using the
`source.path` field from marketplace.json (this may differ from `name` — e.g.,
the `telegram` plugin lives at `plugins/forge-channels-telegram`). Check whether
`<source.path>/.claude-plugin/customizations.json` exists. If it exists, read
the `customizations` array and count entries. If the file does not exist, count
is 0.

---

## § Plugin selection (Step 3)

Present a categorized table of all plugins found in the source marketplace.
Ask the user which to include in the new marketplace.

### Table format

```
## Available plugins

### External (curated from upstream sources)

| Plugin                  | Upstream                                | Customizations |
|-------------------------|-----------------------------------------|----------------|
| forge-superpowers       | obra/superpowers @ v5.0.6               | 19             |
| forge-plugin-dev        | anthropics/claude-code (plugin-dev)     | 0              |
| forge-extended-dev      | anthropics/claude-code (feature-dev + 2)| 0              |
| forge-hookify           | anthropics/claude-code (hookify)        | 0              |
| forge-security          | anthropics/claude-code (security)       | 0              |
| forge-commit            | anthropics/claude-code (commit-commands)| 0              |
| forge-ralph             | anthropics/claude-code (ralph-wiggum)  | 0              |
| forge-frontend-design   | anthropics/claude-plugins-official      | 0              |
| forge-ui-expert         | nextlevelbuilder/ui-ux-pro-max-skill    | 0              |
| telegram                | anthropics/claude-plugins-official      | 0              |

### Native (authored in this repo)

| Plugin              | Source                                   | Customizations |
|---------------------|------------------------------------------|----------------|
| forge-init          | dmedina-dev/dev-forge (plugins/forge-init)   | —          |
| forge-keeper        | dmedina-dev/dev-forge (plugins/forge-keeper) | —          |
| forge-proactive-qa  | dmedina-dev/dev-forge (plugins/forge-proactive-qa) | —    |
```

For the upstream column of external plugins: show `repo @ ref` for single
upstream, or `repo (name + N more)` for arrays.

**Omit forge-export itself from the table** — it is the running exporter and
should not export itself.

### Default and exclusions

Default: all plugins are included. After presenting the table, ask:

> "All plugins are included by default. Enter plugin names to exclude
> (comma-separated), or press Enter to keep all:"

Record excluded names. Remove them from all subsequent steps.

---

## § Customization interview (Step 4)

For each **external** plugin that is selected AND has a
`customizations.json` with at least one entry, run the following interview.

Skip any external plugin with no `customizations.json` or an empty
`customizations` array — nothing to carry.

### Per-plugin interview flow

1. Display the plugin name and upstream source as a header.
2. List each customization entry:

```
## forge-superpowers — 19 customizations from obra/superpowers @ v5.0.6

  [custom-01] excluded  tests/
    "Excluded upstream test infrastructure"
    Reason: Tests are for validating the upstream ecosystem, not relevant to our plugin usage

  [custom-02] excluded  .github/
    "Excluded upstream CI/CD workflows"
    Reason: Upstream project CI, not applicable to dev-forge

  [custom-10] removed   skills/writing-skills/
    "Removed writing-skills skill"
    Reason: Using Anthropic official skill-creator instead

  [custom-12] modified  skills/brainstorming/SKILL.md
    "Reduced trigger sensitivity to complex requirements only"
    Reason: Original trigger was too aggressive, activating brainstorming on simple requests
  ...
```

3. Ask:

> "Which customizations carry over to the new marketplace?
> Options: all / none / list ids (e.g. custom-01,custom-10,custom-12)"

4. Record the selected ids for the generation phase. These will be written
   into the new plugin's `customizations.json`.

### What "carry over" means

- **Carried** customizations are written into the new repo's
  `plugins/<name>/.claude-plugin/customizations.json` verbatim.
- The `origin` and `upstream_status` blocks are copied verbatim from the source
  `customizations.json` (dates are preserved — this is a carry-over, not a fresh fetch).
- Non-carried customizations are omitted from the new file. If none are
  carried, no `customizations.json` is created for that plugin.

---

## § Native plugin interview (Step 5)

For each **native** plugin that is selected, run a short interview.

### Per-plugin interview flow

Ask two questions:

**Question 1 — Content copy:**

> "forge-init is a native plugin authored in this repo.
> Copy the full plugin directory to the new repo? (yes = include all files,
> no = reference-only entry in marketplace.json with a note that content is
> not included)"

- `yes`: the plugin directory is copied in full. Proceed to Question 2.
- `no`: generate a marketplace.json entry only. Add a `note` field:
  `"Content not included — reference only"`. Skip Question 2.

**Question 2 — Author tracking (only if yes):**

> "Enter the new author's name and email for origin tracking in
> customizations.json (format: Name <email>):"

Generate a `customizations.json` tracking the source dev-forge as origin.
See `references/output-schema.md` § customizations.json for copied native
plugins for the exact template and field values.

The author name/email is stored in the new repo's marketplace.json `owner`
field, not in `customizations.json`.

---

## § Settings/hooks detection (Step 6)

After plugin selection is finalized, check for settings that are tied to
selected plugins.

### Check for .claude/settings.json

Look for `.claude/settings.json` in the source repo root. If it does not
exist, skip this step entirely.

### Find plugin-associated hooks

Read the `hooks` array from `settings.json`. For each hook entry, examine
the `command` field. A hook is associated with a plugin if its command
string contains `plugins/<name>` for any selected plugin name.

Group associated hooks by plugin name.

### Present grouped hooks

```
## Settings associated with selected plugins

forge-proactive-qa
  PreToolUse  — "bash ${CLAUDE_PLUGIN_ROOT}/plugins/forge-proactive-qa/hooks/..."
  PostToolUse — "bash ${CLAUDE_PLUGIN_ROOT}/plugins/forge-proactive-qa/hooks/..."

forge-hookify
  PreToolUse  — "bash ${CLAUDE_PLUGIN_ROOT}/plugins/forge-hookify/hooks/..."
  Stop        — "bash ${CLAUDE_PLUGIN_ROOT}/plugins/forge-hookify/hooks/..."

Also present (not plugin-associated):
  [list any remaining hooks not tied to any selected plugin, if any]
```

### Ask which to carry

> "Which hook groups carry over to the new repo's .claude/settings.json?
> Enter plugin names (comma-separated), 'all', or 'none':"

If there are unassociated hooks, ask separately whether to include them.

Record selections. In the generation phase, write a `.claude/settings.json`
in the new repo containing only the selected hook entries.

---

## § Dependency validation

Run dependency validation immediately after plugin selection is finalized
(before Step 4 interviews begin).

### Source of truth

Read `docs/dependencies.md` from the source repo. The hard dependency is
documented in the matrix section as `requires`.

Current known hard dependency: **forge-extended-dev requires forge-superpowers**.

### Check for missing required plugins

For each selected plugin, check whether any plugin it `requires` is also
selected. If a required plugin is missing:

```
Warning: forge-extended-dev requires forge-superpowers, but forge-superpowers
is not in your selection.

Add forge-superpowers? (yes/no):
```

If yes, add it to the selection and re-run dependency validation (the newly
added plugin may itself have requirements). Repeat until no missing
dependencies remain.

### Compute install order

Once selection is finalized (including any auto-added dependencies), compute
the install order for the generated `install-all.md` command:

1. **Required plugins first** — plugins that others depend on (e.g., forge-superpowers)
2. **Independent plugins second** — plugins with no requires/required-by relationship
3. **Dependent plugins last** — plugins that require others (e.g., forge-extended-dev)

Within each group, preserve the order from the source marketplace.json.

Example install order output:

```
Install order:
  1. forge-superpowers   (required by forge-extended-dev)
  2. forge-init          (independent)
  3. forge-keeper        (independent)
  4. forge-commit        (independent)
  5. forge-extended-dev  (requires forge-superpowers)
```

Use this order when generating the `install-all.md` slash command.
