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
{ "name": "forge-deep-review", "upstream": [ { "repo": "..." }, { "repo": "..." } ] }
```

### How to identify native plugins

An entry is native if it has NO `upstream` key. The `source.url` points to
the same dev-forge repository.

```json
{ "name": "forge-init", "source": { "url": "https://github.com/dmedina-dev/dev-forge.git", ... } }
```

### Customization count per plugin

For each plugin (external or native), resolve its directory using the
`source.path` field from marketplace.json (this may differ from `name`). Check whether
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
| forge-deep-review      | anthropics/claude-code (pr-review-toolkit + code-review) | 0     |
| forge-hookify           | anthropics/claude-code (hookify)        | 0              |
| forge-security          | anthropics/claude-code (security)       | 0              |
| forge-commit            | anthropics/claude-code (commit-commands)| 0              |
| forge-frontend-design   | anthropics/claude-plugins-official      | 0              |
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

After plugin selection is finalized, detect ALL hooks in the project and
classify them so the user can decide which to package.

### Check for .claude/settings.json

Look for `.claude/settings.json` in the source repo root. If it does not
exist, skip this step entirely.

### Classify every hook

Read the `hooks` object from `settings.json`. For each event type
(PreToolUse, PostToolUse, Stop, SessionStart, UserPromptSubmit, Notification,
PreCompact), iterate over each hook entry.

Classify each hook into one of three categories:

**Plugin-associated** — command string contains `plugins/<name>` or
`${CLAUDE_PLUGIN_ROOT}` for a selected plugin. These travel with the plugin
and don't need separate packaging.

**Project-level** — command references project scripts (e.g.,
`scripts/hooks/...`), inline bash, or prompt-type hooks with project-specific
content. These are candidates for packaging.

**Infrastructure** — hooks for notifications, session context, or other
system-level concerns not tied to code quality or conventions.

### Diagnose each project-level hook

For each project-level hook, produce a short diagnostic:

1. **Read the hook command or prompt** — if it's a script path, read the
   script file to understand what it does
2. **Determine trigger**: the event type + matcher (e.g., "PreToolUse on
   Edit|Write", "Stop on all", "UserPromptSubmit")
3. **Determine scope of action**: what the hook actually does — one line
   summary (e.g., "Blocks rm -rf and other destructive bash commands",
   "Runs ESLint --fix on edited .ts/.tsx files", "Injects monorepo
   conventions as context")
4. **Assess portability**: is this hook project-specific (references
   project paths, project-specific tools) or generic (useful for any
   project with similar stack)?

### Present diagnostic table

```
## Project-level hooks detected

| # | Event           | Matcher    | Script/Source             | Action                                          | Portable? |
|---|-----------------|------------|---------------------------|------------------------------------------------|-----------|
| 1 | PreToolUse      | Edit|Write | scripts/hooks/protect-files.sh   | Blocks edits to protected files (lock files, generated code) | ⚠ project-specific (hardcoded file list) |
| 2 | PreToolUse      | Bash       | scripts/hooks/block-destructive.sh | Blocks rm -rf, git reset --hard, drop table | ✓ generic |
| 3 | PreToolUse      | Write      | scripts/hooks/validate-imports.sh  | Validates import paths follow conventions  | ⚠ project-specific (import rules) |
| 4 | PostToolUse     | Edit|Write | scripts/hooks/run-domain-tests.sh | Runs domain tests on edited files          | ⚠ project-specific (test runner) |
| 5 | Stop            | —          | scripts/hooks/lint-check.sh       | Runs pnpm lint --fix, blocks on errors     | ✓ generic (any pnpm project) |
| 6 | UserPromptSubmit| —          | inline echo                       | Injects monorepo structure conventions     | ⚠ project-specific (hardcoded conventions) |
| 7 | SessionStart    | —          | scripts/hooks/session-context.sh  | Provides session startup context           | ⚠ project-specific |

Plugin-associated hooks (travel with their plugins, no action needed):
  forge-hookify: PreToolUse, PostToolUse, Stop, UserPromptSubmit
  forge-proactive-qa: PreToolUse, PostToolUse
```

### Ask which to package

> "Which project-level hooks should be packaged into the new marketplace?
> Enter numbers (e.g., 2,5), 'all', or 'none'.
>
> Selected hooks will be bundled as a plugin named `<marketplace-name>-hooks`
> with their scripts copied. Project-specific hooks may need adaptation."

Record selections.

### Packaging as a plugin

Selected project-level hooks are packaged as a new plugin in the generated
marketplace:

```
plugins/<marketplace-name>-hooks/
├── .claude-plugin/
│   └── plugin.json
├── hooks/
│   ├── hooks.json         ← converted from settings.json format
│   └── <script-name>.sh   ← copied scripts, paths rewritten to ${CLAUDE_PLUGIN_ROOT}
└── README.md              ← documents each hook's trigger and purpose
```

**Conversion rules:**
- `settings.json` hook entries become `hooks.json` entries
- Script paths rewrite from `scripts/hooks/<name>.sh` to
  `${CLAUDE_PLUGIN_ROOT}/hooks/<name>.sh`
- Inline commands (`bash -c '...'`) become script files for readability
- Prompt-type hooks stay as `"type": "prompt"` entries
- The plugin.json gets `name`, `version: "1.0.0"`, `description` listing
  the packaged hooks
- Add entry to generated marketplace.json as a native plugin

### Plugin-associated hooks

Plugin-associated hooks do NOT need packaging — they are already part of
their plugin's `hooks/hooks.json` and will work when the plugin is installed.
Just confirm they are present and note them in the summary.

---

## § Dependency validation

Run dependency validation immediately after plugin selection is finalized
(before Step 4 interviews begin).

### Source of truth

Read `docs/dependencies.md` from the source repo. The hard dependency is
documented in the matrix section as `requires`.

Current known hard dependency: **forge-brainstorming requires forge-superpowers**.

### Check for missing required plugins

For each selected plugin, check whether any plugin it `requires` is also
selected. If a required plugin is missing:

```
Warning: forge-brainstorming requires forge-superpowers, but forge-superpowers
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
3. **Dependent plugins last** — plugins that require others (e.g., forge-brainstorming)

Within each group, preserve the order from the source marketplace.json.

Example install order output:

```
Install order:
  1. forge-superpowers   (required by forge-brainstorming)
  2. forge-init          (independent)
  3. forge-keeper        (independent)
  4. forge-commit        (independent)
  5. forge-brainstorming (requires forge-superpowers)
```

Use this order when generating the `install-all.md` slash command.
