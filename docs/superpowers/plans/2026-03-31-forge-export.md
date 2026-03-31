# forge-export Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create the `forge-export` plugin — a disposable, interview-driven skill that generates a new standalone marketplace repository from an existing dev-forge marketplace, letting teams create their own curated plugin collections with full customization and update support.

**Architecture:** Single skill with 2 reference files plus 1 command entry point. The skill orchestrates an 8-step interview (name, path, plugin selection, customizations, native copies, settings, confirmation, write). References hold detection/interview logic and output file schemas. No hooks, no agents, no scripts — pure prose-driven workflow identical to forge-init.

**Tech Stack:** Claude Code plugin system (SKILL.md, commands, references, plugin.json, marketplace.json)

---

### Task 1: Plugin skeleton — plugin.json

**Files:**
- Create: `plugins/forge-export/.claude-plugin/plugin.json`

**Pattern reference:** Read `plugins/forge-init/.claude-plugin/plugin.json` for exact structure.

- [ ] **Step 1: Create plugin.json**

  ```json
  {
    "name": "forge-export",
    "version": "1.0.0",
    "description": "Exports a dev-forge marketplace into a new standalone repository. Interview-driven: select plugins, apply customizations, generate complete marketplace structure. Designed to be uninstalled after use.",
    "author": {
      "name": "dmedina",
      "email": "me@dmedina.dev"
    },
    "repository": "https://github.com/dmedina-dev/dev-forge",
    "license": "MIT",
    "keywords": ["export", "marketplace", "scaffold", "bootstrap", "fork", "disposable"]
  }
  ```

- [ ] **Step 2: Validate JSON**

  ```bash
  python3 -m json.tool plugins/forge-export/.claude-plugin/plugin.json
  ```

- [ ] **Step 3: Commit**

  `feat(forge-export): add plugin skeleton`

---

### Task 2: Command entry point — export.md

**Files:**
- Create: `plugins/forge-export/commands/export.md`

**Pattern reference:** Read `plugins/forge-init/commands/init.md` for structure and tone.

- [ ] **Step 1: Create export.md**

  YAML frontmatter with `description` field. Body: brief explanation of what the command does, then reference to the forge-export skill. Include the disposable uninstall note at the end, mirroring forge-init's init.md.

  ```yaml
  ---
  description: Export this dev-forge marketplace into a new standalone marketplace repository. Runs an interview to select plugins, resolve customizations, and write the complete output structure.
  ---
  ```

  Body should explain:
  - What happens: interview → detection → selection → generation
  - That the skill runs the forge-export skill
  - Post-completion: uninstall reminder

- [ ] **Step 2: Verify frontmatter has `description` field** (required by plugin-authoring rules)

- [ ] **Step 3: Commit**

  `feat(forge-export): add /export command entry point`

---

### Task 3: Reference — interview-guide.md

**Files:**
- Create: `plugins/forge-export/skills/forge-export/references/interview-guide.md`

**Convention:** Plain markdown, NO frontmatter (reference files never have frontmatter).

- [ ] **Step 1: Write interview-guide.md**

  This reference covers detection logic and interview behavior for Steps 2-6 of the skill. Sections:

  **§ Plugin classification**
  - How to identify external plugins: has `upstream` key in marketplace.json entry
  - How to identify native plugins: no `upstream` key, source URL points to same repo
  - For each plugin: check if `plugins/<name>/.claude-plugin/customizations.json` exists, count entries

  **§ Plugin selection (Step 3)**
  - Present categorized table (external vs native) with columns: name, upstream/source, customization count
  - Default: all plugins included
  - User can exclude by name

  **§ Customization interview (Step 4)**
  - For each selected external plugin WITH `customizations.json`:
    - Read the file, present each entry: id, type, target, summary, reason
    - Ask: "Which customizations carry over?" — accept all / none / specific ids
    - Record selections for generation phase
  - If plugin has NO customizations.json: skip, nothing to carry

  **§ Native plugin interview (Step 5)**
  - For each selected native plugin, ask:
    1. Copy content to the new repo? (yes = full directory copy, no = reference-only marketplace.json entry noting it's not included)
    2. If yes: ask new author name and email for the `customizations.json` origin tracking
    3. Pre-fill `origin.repo` with source dev-forge repo URL, `origin.fetched_at` with today's date

  **§ Settings/hooks detection (Step 6)**
  - Check if source repo has `.claude/settings.json`
  - Find hook entries whose command references `plugins/<name>` for any selected plugin
  - Present grouped by plugin: "These settings are associated with selected plugins"
  - Ask which to carry over to the new repo's `.claude/` directory

  **§ Dependency validation**
  - After plugin selection, read `docs/dependencies.md` from source repo
  - Check for missing hard dependencies (e.g., forge-extended-dev selected without forge-superpowers)
  - Warn and offer to add missing required plugins
  - Compute install order for the generated install-all.md: required plugins first, then independents, then dependents

- [ ] **Step 2: Verify file has NO frontmatter** (reference convention)

- [ ] **Step 3: Commit**

  `feat(forge-export): add interview-guide reference`

---

### Task 4: Reference — output-schema.md

**Files:**
- Create: `plugins/forge-export/skills/forge-export/references/output-schema.md`

**Convention:** Plain markdown, NO frontmatter.

**Pattern references to read before writing:**
- `.claude-plugin/marketplace.json` — for marketplace.json shape
- `plugins/forge-superpowers/.claude-plugin/customizations.json` — for customizations.json shape
- `docs/customizations-pattern.md` — for full customizations schema
- `plugins/forge-init/commands/install-all.md` — for install-all command shape
- `docs/dependencies.md` — for dependencies.md shape

- [ ] **Step 1: Write output-schema.md**

  This reference documents every file the export generates and the rules for writing them. Sections:

  **§ Generated file manifest**
  Complete list of files written to `<dest>/`:
  ```
  .claude-plugin/marketplace.json
  plugins/<name>/                    (for each copied native plugin)
  plugins/<name>/.claude-plugin/customizations.json  (for each tracked plugin)
  commands/install-all.md
  CLAUDE.md
  README.md
  docs/dependencies.md
  ```

  **§ marketplace.json**
  - Top-level: `name` (from interview), `owner` (from interview or source), `metadata` (description, version "1.0.0"), `plugins[]`
  - **CRITICAL: External plugin entries** — `source.url` MUST point to the ORIGINAL upstream URL (e.g., `https://github.com/obra/superpowers.git`), NOT to the source dev-forge repo. The `upstream` block is copied from source marketplace.json. This makes the new marketplace independently installable.
  - **Native plugin entries (copied)** — `source.url` points to the NEW marketplace repo URL (ask user for their repo URL or use a placeholder). `source.path` is `plugins/<name>`. No `upstream` block — the new repo IS the source. A `customizations.json` tracks the original dev-forge as origin.
  - **Native plugin entries (not copied, reference-only)** — `source.url` points to the source dev-forge repo, `source.path` is `plugins/<name>`. Add a note in description that it's a reference, content lives in source repo.

  **§ customizations.json for copied native plugins**
  ```json
  {
    "origin": {
      "type": "github",
      "repo": "<source-dev-forge-repo>",
      "path": "plugins/<name>",
      "ref": "<source-plugin-version>",
      "commit": "",
      "fetched_at": "<today>",
      "check_url": "<source-dev-forge-releases-url>"
    },
    "upstream_status": {
      "last_checked": "<today>",
      "latest_ref": "<source-plugin-version>",
      "latest_commit": "",
      "has_updates": false,
      "summary": "",
      "changes": []
    },
    "customizations": []
  }
  ```
  Starts with empty `customizations[]` — the new owner adds entries as they diverge.

  **§ customizations.json for external plugins with carried customizations**
  - Copy `origin` block verbatim from source customizations.json
  - Copy `upstream_status` block verbatim
  - `customizations[]` contains ONLY the entries the user chose to carry over (filtered by id)

  **§ install-all.md command**
  - Same structure as `plugins/forge-init/commands/install-all.md`
  - Catalog table lists only included plugins
  - Working vs configuration split: working = all included plugins; configuration = forge-export itself (if the new marketplace ships forge-export)
  - Dependency ordering: required plugins first, then independents, then dependents
  - Steps 1-5 identical to source pattern but with correct plugin list

  **§ CLAUDE.md**
  Minimal marketplace CLAUDE.md (~60 lines). Sections:
  - Marketplace name and purpose
  - Architecture block showing `plugins/` tree
  - Plugin independence note
  - Commands section (test independently with `claude --plugin-dir`)
  - @import to `docs/dependencies.md`

  **§ README.md**
  Human-readable. Sections:
  - Marketplace name as H1
  - Description + "Built from [source marketplace name]" attribution
  - Plugin table: name, description, source (with links to upstream repos)
  - Quick start: how to install the marketplace + install-all
  - Customization: how to add your own customizations.json
  - Updates: how the customizations.json pattern supports upstream updates
  - Attribution: links to all upstream plugin repos

  **§ docs/dependencies.md**
  - Same format as source `docs/dependencies.md`
  - Filtered to only include rows for selected plugins
  - Matrix table with requires/complements/independent columns

  **§ Generation rules**
  - Directory creation order: `<dest>/` → `.claude-plugin/` → `plugins/` → `docs/` → `commands/`
  - Native plugin copy: full directory tree from source, then write customizations.json
  - External plugins: NO file copy — they install from upstream at install time
  - For external plugins with carried customizations: create `plugins/<name>/.claude-plugin/customizations.json` only
  - Destination validation: confirm path does not exist before writing; if it does, stop
  - `git init` in `<dest>/`, stage all files, commit with message `"init: <marketplace-name> marketplace"`
  - Post-write summary format: list all files written, git status, uninstall reminder

- [ ] **Step 2: Verify file has NO frontmatter**

- [ ] **Step 3: Commit**

  `feat(forge-export): add output-schema reference`

---

### Task 5: Core skill — SKILL.md

**Files:**
- Create: `plugins/forge-export/skills/forge-export/SKILL.md`

**Pattern reference:** Read `plugins/forge-init/skills/forge-init/SKILL.md` for exact structure, frontmatter pattern, and step format.

**CRITICAL CONSTRAINT:** Must stay under 200 lines. Each step is concise prose — detail lives in references.

- [ ] **Step 1: Write SKILL.md**

  **Frontmatter:**
  ```yaml
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
  ```

  **Body — 8 steps:**

  ```markdown
  # Forge Export

  Generate a new standalone marketplace repository from this dev-forge installation.

  ## Step 1 — Name and destination

  Ask the user:
  1. Marketplace name (e.g., "acme-forge")
  2. Destination path (absolute or relative, e.g., ~/acme-forge)

  Validate the destination path does not already exist. If it does, stop and report.

  ## Step 2 — Detect plugins

  Read `.claude-plugin/marketplace.json` in this repo. Classify each plugin
  as external (has `upstream` key) or native (no `upstream`). For each, check
  if `plugins/<name>/.claude-plugin/customizations.json` exists and count entries.

  See `references/interview-guide.md` § Plugin classification.

  ## Step 3 — Select plugins

  Present detected plugins in a categorized table:

  ### External (curated from upstream)
  | Plugin | Upstream | Customizations |
  |--------|----------|----------------|

  ### Native (original to this marketplace)
  | Plugin | Description |
  |--------|-------------|

  Ask which to include. Default: all. Validate dependencies — if
  forge-extended-dev is selected without forge-superpowers, warn and offer
  to add it.

  See `references/interview-guide.md` § Dependency validation.

  ## Step 4 — Customizations per plugin

  For each selected external plugin that has customizations, present each
  entry and ask which to carry over.

  See `references/interview-guide.md` § Customization interview.

  ## Step 5 — Native plugin treatment

  For each selected native plugin, ask:
  1. Copy content to the new repo? (yes/no)
  2. If yes: authorship info for origin tracking

  See `references/interview-guide.md` § Native plugin interview.

  ## Step 6 — Settings and hooks

  Detect settings/hooks in `.claude/settings.json` related to selected plugins.
  Ask which to export.

  See `references/interview-guide.md` § Settings/hooks detection.

  ## Step 7 — Confirm and generate

  Build the complete output plan in memory. Present summary:
  - Marketplace name and destination
  - Plugins included (type, customizations count)
  - Files that will be written
  - Native plugins that will be copied

  **DO NOT write files until the user explicitly confirms.**

  See `references/output-schema.md` for all generated file shapes.

  ## Step 8 — Write output

  On confirmation:
  1. Create directory structure
  2. Write marketplace.json, CLAUDE.md, README.md, docs/dependencies.md,
     commands/install-all.md
  3. Copy native plugin directories, write their customizations.json
  4. Write customizations.json for external plugins with carried customizations
  5. Run `git init` + initial commit in destination

  See `references/output-schema.md` § Generation rules.

  Post-write: show summary of files written and uninstall reminder:
  ```
  To uninstall forge-export (no longer needed):
    /plugin → Manage and uninstall plugins → forge-export → Uninstall
  ```

  ## References

  - Interview logic → `references/interview-guide.md`
  - Output schemas and generation rules → `references/output-schema.md`
  ```

- [ ] **Step 2: Verify SKILL.md is under 200 lines**

  ```bash
  wc -l plugins/forge-export/skills/forge-export/SKILL.md
  ```

- [ ] **Step 3: Verify frontmatter has `name` and `description` fields** (required by plugin-authoring rules)

- [ ] **Step 4: Verify description contains trigger phrases** — "export marketplace", "create marketplace", "fork dev-forge", etc.

- [ ] **Step 5: Commit**

  `feat(forge-export): add core skill with 8-step interview flow`

---

### Task 6: Register in marketplace and dependencies

**Files:**
- Modify: `.claude-plugin/marketplace.json:203` — add entry after forge-proactive-qa
- Modify: `docs/dependencies.md:106` — add row to matrix and narrative section

- [ ] **Step 1: Add forge-export to marketplace.json**

  Add after the forge-proactive-qa entry (before the closing `]`):

  ```json
  ,
  {
    "name": "forge-export",
    "description": "Exports a dev-forge marketplace into a new standalone marketplace repository. Interview-driven: select plugins, apply customizations, generate complete structure. Disposable — uninstall after use.",
    "source": {
      "source": "git-subdir",
      "url": "https://github.com/dmedina-dev/dev-forge.git",
      "path": "plugins/forge-export"
    },
    "version": "1.0.0"
  }
  ```

- [ ] **Step 2: Validate marketplace.json**

  ```bash
  python3 -m json.tool .claude-plugin/marketplace.json > /dev/null
  ```

- [ ] **Step 3: Add forge-export to dependencies.md**

  Add narrative section before the matrix:
  ```markdown
  ### forge-export
  - **Independent** — standalone exporter, no dependencies
  - Install on demand, uninstall after use (disposable like forge-init)
  ```

  Add row to matrix table:
  ```
  forge-export              -                   -                   everything else
  ```

  Add forge-export to the "Configuration plugins" category in the install-all.md description context — it's a disposable utility, not a working plugin.

- [ ] **Step 4: Commit**

  `feat(forge-export): register in marketplace and dependency map`

---

### Task 7: Validation and smoke test

**Files:**
- Read all created files for final review

- [ ] **Step 1: Validate all JSON files**

  ```bash
  python3 -m json.tool plugins/forge-export/.claude-plugin/plugin.json > /dev/null
  python3 -m json.tool .claude-plugin/marketplace.json > /dev/null
  ```

- [ ] **Step 2: Verify SKILL.md line count**

  ```bash
  wc -l plugins/forge-export/skills/forge-export/SKILL.md
  ```

  Must be under 200 lines.

- [ ] **Step 3: Verify all critical invariants in content**

  Read through all files and verify:
  - [ ] SKILL.md frontmatter has `name` and `description` with trigger phrases
  - [ ] export.md frontmatter has `description`
  - [ ] interview-guide.md has NO frontmatter
  - [ ] output-schema.md has NO frontmatter
  - [ ] output-schema.md § marketplace.json specifies external plugins point to ORIGINAL upstream
  - [ ] output-schema.md § customizations.json shows empty `customizations[]` for new native copies
  - [ ] SKILL.md Step 7 has explicit "DO NOT write files until confirmed"
  - [ ] SKILL.md Step 8 includes git init + uninstall reminder
  - [ ] marketplace.json entry uses https URL (not git@)

- [ ] **Step 4: Plugin load test**

  ```bash
  claude --plugin-dir plugins/forge-export -p "list available commands"
  ```

  Verify forge-export skill and /export command appear in the output.

- [ ] **Step 5: Final commit (if any fixes needed)**

  `fix(forge-export): address validation findings`
