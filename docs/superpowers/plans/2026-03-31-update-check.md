# forge-keeper:update-check Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a `/forge-keeper:update-check` command that checks plugins for upstream updates, shows changes and conflicts with local customizations, and applies updates preserving customizations.

**Architecture:** One command file + one reference file. The command is the interactive entry point; the reference holds detailed check/merge logic. No hooks, no scripts — pure prose.

**Tech Stack:** Claude Code plugin system, `gh api` / `git ls-remote` for upstream checks, `git clone --depth 1` for fetching content.

---

### Task 1: Reference — update-check-guide.md

**Files:**
- Create: `plugins/forge-keeper/skills/forge-keeper/references/update-check-guide.md`

**Convention:** Plain markdown, NO frontmatter.

- [ ] **Step 1: Write update-check-guide.md**

  This reference covers the full upstream check and merge logic. Sections:

  **§ Plugin scanning**
  - Scan all `plugins/*/.claude-plugin/customizations.json` files
  - Support two schema variants:
    - `origin` (single object) — standard case (forge-superpowers, forge-commit, etc.)
    - `origins` (array) — multi-source case (forge-extended-dev)
  - Skip plugins where `origin.type` is `"native"` (e.g., forge-proactive-qa) — no upstream to check
  - Skip plugins without `customizations.json` — they are native plugins (forge-init, forge-keeper)
  - Collect: plugin name, source path, origin(s), current ref, customizations list

  **§ Upstream check**
  - For each origin with a tag-style ref (e.g., `v5.0.6`):
    - Primary: `gh api repos/{owner}/{repo}/releases/latest` to get latest release tag
    - Fallback: `git ls-remote --tags https://github.com/{owner}/{repo}.git` and pick the highest semver tag
    - Compare: if latest tag != origin.ref → has updates
  - For each origin with a branch ref (e.g., `main`):
    - Primary: `gh api repos/{owner}/{repo}/commits/{branch} --jq '.sha'` to get HEAD SHA
    - Fallback: `git ls-remote https://github.com/{owner}/{repo}.git refs/heads/{branch}` for HEAD SHA
    - Compare: if HEAD SHA != origin.commit → has updates (if origin.commit is empty, always flag as "unknown — no commit tracked")
  - For multi-origin plugins (`origins[]`): check each origin independently, aggregate results

  **§ Quick summary format**
  After checking all plugins, present a summary table:
  ```
  ## Plugin Update Check

  | Plugin | Upstream | Current | Latest | Status |
  |--------|----------|---------|--------|--------|
  | forge-superpowers | obra/superpowers | v5.0.6 | v5.1.0 | ⚡ 1 release ahead |
  | forge-commit | anthropics/claude-code | main | main | ✓ up to date |
  | forge-hookify | anthropics/claude-code | main | main@abc1234 | ⚡ new commits |
  | forge-extended-dev | (3 origins) | mixed | mixed | ⚡ 2/3 have updates |
  | forge-proactive-qa | (native) | — | — | ⊘ skipped |

  N plugins checked, M have updates available.
  ```

  **§ Detailed view per plugin**
  When user asks for details on a specific plugin:
  - Show current origin info (repo, ref, fetched_at)
  - Show what's new upstream:
    - For tag-based: list releases between current and latest (via `gh api repos/{owner}/{repo}/releases`)
    - For branch-based: show commit count and recent commits (via `gh api repos/{owner}/{repo}/compare/{old_sha}...{branch}`)
  - Show conflict analysis:
    - List all local customizations (from customizations[])
    - For each customization of type `modified`: flag as potential conflict if the same target file changed upstream
    - For `excluded` and `removed`: flag if the excluded/removed content was significantly changed upstream
    - For `added`: no conflict (local-only content)

  Format per the customizations-pattern.md "Detailed check" format:
  ```
  ## forge-superpowers — obra/superpowers

  Current: v5.0.6 (fetched 2026-03-29)
  Latest: v5.1.0

  v5.1.0 (2026-04-15): Inline self-review replacing subagent loops
    Files: skills/brainstorming/SKILL.md, hooks/hooks.json
    ⚠ skills/brainstorming/SKILL.md — you modified the trigger (custom-12)
    ✓ hooks/hooks.json — no conflicts

  v5.0.7 (2026-04-01): Bug fixes for session-start hook
    Files: hooks/session-start
    ✓ No conflicts with your customizations
  ```

  **§ Apply update flow**
  When user wants to apply an update to a specific plugin:

  1. **Fetch upstream content:**
     - `git clone --depth 1 --branch <latest_ref> https://github.com/<repo>.git /tmp/upstream-<name>`
     - If branch-based (main): just `git clone --depth 1 https://github.com/<repo>.git /tmp/upstream-<name>`

  2. **Identify changes:**
     - Compare upstream content at `<origin.path>/` with local `plugins/<name>/`
     - List files: added upstream, modified upstream, removed upstream

  3. **Apply non-conflicting changes:**
     - New files upstream that aren't in `customizations[]` as excluded/removed → copy to local
     - Modified files upstream that aren't in `customizations[]` as modified → overwrite local
     - Removed files upstream → remove local (unless in customizations as added)

  4. **Handle conflicts:**
     - For files that changed upstream AND are in customizations as `modified`:
       - Show upstream version vs local version side by side
       - Show the customization reason from customizations.json
       - Ask: keep local / take upstream / manual merge
     - For files that changed upstream AND are in customizations as `excluded`:
       - Show what upstream changed
       - Ask: continue excluding / include now

  5. **Handle reset option:**
     - If user wants to discard all customizations and start fresh:
       - Copy entire upstream plugin directory
       - Reset customizations.json: keep origin block, empty customizations[]
       - User can re-create customizations from scratch

  6. **Update tracking:**
     - Update `origin.ref` to new ref/tag
     - Update `origin.commit` if available
     - Update `origin.fetched_at` to today
     - Update `upstream_status.last_checked` to today
     - Update `upstream_status.latest_ref` to new ref
     - Update `upstream_status.has_updates` to false
     - Remove applied customizations if files were reset

  7. **Cleanup:**
     - Remove `/tmp/upstream-<name>` directory
     - Commit changes: `chore(<plugin-name>): update from upstream <old_ref> → <new_ref>`

  **§ Multi-origin plugins**
  For plugins with `origins[]` (e.g., forge-extended-dev):
  - Check each origin independently
  - Present results grouped by origin
  - Apply updates per origin (each origin maps to a subset of the plugin's files via `origin.path`)
  - Handle conflicts per origin

- [ ] **Step 2: Verify NO frontmatter**

- [ ] **Step 3: Commit**

  `feat(forge-keeper): add update-check-guide reference`

---

### Task 2: Command — update-check.md

**Files:**
- Create: `plugins/forge-keeper/commands/update-check.md`

**Pattern reference:** Read `plugins/forge-keeper/commands/status.md` for command structure.

- [ ] **Step 1: Write update-check.md**

  YAML frontmatter with `description` field.

  ```yaml
  ---
  description: Check plugins for upstream updates, show changes and conflicts with local customizations, and optionally apply updates.
  ---
  ```

  Body — interactive 4-step flow:

  **Step 1 — Scan plugins**
  Scan all `plugins/*/.claude-plugin/customizations.json`. Classify each plugin. Skip native-type and plugins without customizations.json.

  See `references/update-check-guide.md` § Plugin scanning.

  **Step 2 — Check upstreams**
  For each eligible plugin, check upstream for new versions using `gh api` (primary) or `git ls-remote` (fallback).

  Present quick summary table.

  See `references/update-check-guide.md` § Upstream check and § Quick summary format.

  **Step 3 — Detail on request**
  Ask: "Want details on any plugin? Enter name(s) or 'all', or Enter to skip."

  For each requested plugin, show releases/commits since current version and conflict analysis with local customizations.

  See `references/update-check-guide.md` § Detailed view per plugin.

  **Step 4 — Apply on request**
  Ask: "Apply updates to any plugin? Enter name(s), or Enter to skip."

  For each plugin to update:
  - Offer: apply (preserve customizations) / reset (fresh start) / skip
  - Execute the chosen action
  - Show post-update summary

  See `references/update-check-guide.md` § Apply update flow.

- [ ] **Step 2: Verify frontmatter has `description`**

- [ ] **Step 3: Commit**

  `feat(forge-keeper): add /update-check command`

---

### Task 3: Update forge-keeper SKILL.md description

**Files:**
- Modify: `plugins/forge-keeper/skills/forge-keeper/SKILL.md:4-8` — add update-check mention to description triggers

- [ ] **Step 1: Add trigger phrase**

  Add "update check", "check upstream", "check for updates" to the SKILL.md description field so the skill can mention the command when relevant.

  Do NOT add update-check logic to the SKILL.md body — it's a standalone command, not part of the sync flow. Just add a brief mention in a new "## Related commands" section at the bottom (before References):

  ```markdown
  ## Related commands

  - `/forge-keeper:update-check` — check plugins for upstream updates and apply them
  ```

- [ ] **Step 2: Verify SKILL.md stays under 200 lines**

- [ ] **Step 3: Commit**

  `feat(forge-keeper): mention update-check in SKILL.md`

---

### Task 4: Bump forge-keeper version

**Files:**
- Modify: `plugins/forge-keeper/.claude-plugin/plugin.json` — version 1.0.1 → 1.1.0 (minor: new command)
- Modify: `.claude-plugin/marketplace.json` — forge-keeper version 1.0.1 → 1.1.0

- [ ] **Step 1: Bump plugin.json**
- [ ] **Step 2: Bump marketplace.json**
- [ ] **Step 3: Validate JSON**
- [ ] **Step 4: Commit**

  `chore(forge-keeper): bump to 1.1.0 for update-check command`

---

### Task 5: Validation

**Files:** Read all created/modified files

- [ ] **Step 1: Verify all critical invariants**
  - update-check.md has `description` frontmatter
  - update-check-guide.md has NO frontmatter
  - SKILL.md under 200 lines
  - All JSON valid
  - Version consistency between plugin.json and marketplace.json

- [ ] **Step 2: Content review**
  - update-check-guide.md covers: scanning, checking, summary, detail, apply, multi-origin
  - update-check.md has 4-step interactive flow
  - Guide references `gh api` with `git ls-remote` fallback
  - Guide handles tag-based AND branch-based refs
  - Guide handles `origin` AND `origins[]`
  - Guide excludes `type: "native"` plugins
  - Apply flow includes reset option
