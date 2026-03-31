# Update Check Guide

Reference for checking and applying upstream updates to external plugins in dev-forge.
Use this when running an update check, reviewing upstream changes, or applying a merge.

## Plugin Scanning

Scan every plugin directory to find which ones have upstream sources to check.

### Steps

1. List all plugins: `plugins/*/.claude-plugin/customizations.json`
2. For each file found, read and classify the plugin:

**Single-origin plugins** (`origin` key, singular) — e.g., forge-superpowers:
```json
{ "origin": { "type": "github", "repo": "obra/superpowers", "ref": "v5.0.6", ... } }
```

**Multi-origin plugins** (`origins` key, array) — e.g., forge-extended-dev:
```json
{ "origins": [ { "repo": "anthropics/claude-code", "path": "plugins/feature-dev", "ref": "main" }, ... ] }
```

**Native plugins** (`origin.type: "native"`) — e.g., forge-proactive-qa:
```json
{ "origin": { "type": "native", "note": "..." } }
```

### Skip rules

- Skip `origin.type: "native"` — no upstream, nothing to check
- Skip plugins with no `customizations.json` — they are native dev-forge plugins
- If `origins` array contains an entry with `type: "native"`, skip only that entry

### Collected data per plugin

For each non-skipped plugin, record:
- Plugin name (directory name under `plugins/`)
- customizations.json path
- Origin(s): repo, path (may be empty string), current ref, fetched_at
- Customizations list: id, type, target, summary, reason
- Whether it's single-origin or multi-origin

---

## Upstream Check

Determine whether newer versions exist for each origin.

### Tag-style refs (e.g., v5.0.6)

A ref that starts with `v` followed by a version number is a tag-style ref.

**Primary method — GitHub releases API:**
```bash
gh api repos/{owner}/{repo}/releases/latest --jq '{tag: .tag_name, published: .published_at, body: .body}'
```
Example for forge-superpowers:
```bash
gh api repos/obra/superpowers/releases/latest --jq '{tag: .tag_name, published: .published_at, body: .body}'
```

**Fallback — git ls-remote:**
```bash
git ls-remote --tags https://github.com/{owner}/{repo}.git 'refs/tags/v*'
```
Parse the output, strip `refs/tags/` prefix, pick the highest semver tag.

**Determine if updates exist:** compare current `ref` against latest tag using semver ordering. If latest > current → `has_updates: true`.

### Branch refs (e.g., main)

A ref that matches a branch name (main, master, etc.) is a branch ref.

**Primary method — GitHub commits API:**
```bash
gh api repos/{owner}/{repo}/commits/{branch} --jq '{sha: .sha, date: .commit.committer.date, message: .commit.message}'
```
Example for forge-extended-dev (checking `anthropics/claude-code`, branch `main`):
```bash
gh api repos/anthropics/claude-code/commits/main --jq '{sha: .sha, date: .commit.committer.date, message: .commit.message}'
```

**Fallback — git ls-remote:**
```bash
git ls-remote https://github.com/{owner}/{repo}.git refs/heads/{branch}
```
Returns the current commit SHA for the branch tip.

**Determine if updates exist:** compare current `commit` SHA against latest SHA. If different and `commit` field is non-empty → `has_updates: true`. If current `commit` is empty, record the latest SHA but treat as "unknown — needs baseline commit recorded".

### Subpath repos (forge-extended-dev pattern)

When `path` is non-empty (e.g., `"path": "plugins/feature-dev"`), there is no per-subdirectory release. Check the repo-level latest commit and note the subpath:

```bash
gh api repos/anthropics/claude-code/commits/main --jq '{sha: .sha, date: .commit.committer.date}'
```

To find commits that touched the specific subpath (more precise):
```bash
gh api "repos/anthropics/claude-code/commits?path=plugins/feature-dev&sha=main&per_page=1" --jq '.[0] | {sha: .sha, date: .commit.committer.date, message: .commit.message}'
```

### Multi-origin plugins

Check each origin in the `origins` array independently, using the method appropriate to its `ref` type. Each origin has its own repo, path, and ref — treat them as separate checks.

---

## Quick Summary Format

After scanning all plugins and checking upstreams, produce a table:

```
Plugin Update Status — 2026-03-31
═══════════════════════════════════════════════════════════════════════
Plugin                  Upstream                     Current    Latest     Status
─────────────────────── ──────────────────────────── ────────── ────────── ──────
forge-superpowers       obra/superpowers             v5.0.6     v5.1.0     ⚡
forge-extended-dev      anthropics/claude-code       main       main       ✓
forge-hookify           anthropics/claude-code       main       main       ✓
forge-ralph             anthropics/claude-code       main       main       ✓
forge-security          anthropics/claude-code       main       main       ✓
forge-commit            anthropics/claude-code       main       main       ✓
forge-frontend-design   anthropics/claude-code       main       main       ✓
forge-ui-expert         anthropics/claude-code       main       main       ✓
forge-channels-telegram anthropics/claude-code       main       main       ✓
forge-proactive-qa      —                            —          —          ⊘ (native)
forge-keeper            —                            —          —          ⊘ (native)
═══════════════════════════════════════════════════════════════════════
⚡ 1 plugin has updates   ✓ 8 up to date   ⊘ 2 skipped
```

**Status icons:**
- `⚡` — updates available
- `✓` — up to date
- `⊘` — skipped (native or no customizations.json)

After the table, list any plugins with updates and one-line summaries:
```
⚡ forge-superpowers: v5.0.6 → v5.1.0 — "Inline self-review + brainstorm server improvements"
   ⚠ 1 potential conflict (skills/brainstorming/SKILL.md — modified in custom-12)
```

---

## Detailed View Per Plugin

When the user asks for details on a specific plugin or on all plugins with updates, produce the detailed view.

### Format

```
forge-superpowers
  Origin:   obra/superpowers @ v5.0.6 (fetched 2026-03-29)
  Latest:   v5.1.0 (2026-04-15)
  Releases since current: 2

  v5.1.0 (2026-04-15): Inline self-review replacing subagent loops
    Files changed: skills/brainstorming/SKILL.md, hooks/hooks.json, hooks/session-start
    ⚠ skills/brainstorming/SKILL.md — conflicts with custom-12 (modified: reduced trigger sensitivity)
    ✓ hooks/hooks.json — conflicts with custom-13 (modified: removed Cursor platform detection)
    ✓ hooks/session-start — conflicts with custom-14 (modified: Claude Code only)

  v5.0.7 (2026-04-01): Bug fixes for session-start hook
    Files changed: hooks/session-start
    ⚠ hooks/session-start — conflicts with custom-14 (modified: Claude Code only)
```

### Conflict analysis rules

For each file changed upstream, cross-reference against local `customizations[]`:

- **`modified` customization + same file changed upstream** → `⚠` potential conflict. Show: `⚠ {file} — conflicts with {id} ({summary})`
- **`removed` customization + same file or parent dir changed upstream** → `⚠` flag. Show: `⚠ {file} — you removed this (reason from customization)`
- **`excluded` customization + significant changes to excluded dir upstream** → `⚠` flag. Show: `⚠ {dir} — excluded (reason), but upstream changed it significantly`
- **`added` customization + file changed upstream** → no conflict (local-only additions don't conflict). Show: `✓ local addition — no upstream conflict`
- **No matching customization** → `✓` clean. Show: `✓ {file} — no conflicts`

"Significant change" for excluded dirs: if upstream release notes mention the excluded area explicitly, or if more than 3 files changed inside it.

### Fetching changed files for a release

To get the list of files changed in a specific release (tag-based):
```bash
gh api repos/{owner}/{repo}/compare/{old_tag}...{new_tag} --jq '.files[].filename'
```
Example:
```bash
gh api repos/obra/superpowers/compare/v5.0.6...v5.1.0 --jq '.files[].filename'
```

For branch-based, compare commit SHAs:
```bash
gh api repos/{owner}/{repo}/compare/{old_sha}...{new_sha} --jq '.files[].filename'
```

When the subpath is non-empty, filter files to only those under the subpath:
```bash
gh api "repos/anthropics/claude-code/compare/{old_sha}...{new_sha}" \
  --jq '.files[].filename | select(startswith("plugins/feature-dev/"))'
```

---

## Apply Update Flow

When the user confirms they want to apply an update to a plugin, follow these 7 steps.

### Step 1 — Fetch upstream

Clone the upstream source to a temp directory:
```bash
# For tag refs:
git clone --depth 1 --branch v5.1.0 https://github.com/obra/superpowers.git /tmp/upstream-forge-superpowers

# For branch refs:
git clone --depth 1 --branch main https://github.com/anthropics/claude-code.git /tmp/upstream-forge-extended-dev
```

If the origin has a non-empty `path`, the relevant source is at `/tmp/upstream-{plugin}/{path}/`.

### Step 2 — Identify changes

Compare upstream source against the local plugin directory. Produce a list of:
- Files present upstream but missing locally (new upstream files)
- Files present locally but missing upstream (local additions — could be `added` customizations)
- Files present in both but different (potential updates or conflicts)

Use `diff -rq /tmp/upstream-{plugin}/{path}/ plugins/{plugin-name}/` to get a quick diff list.

For each changed file, check whether it matches any customization target. Build two lists:
- **Clean changes**: changed files with no matching customization
- **Conflicting changes**: changed files where a customization exists (type: modified or removed; treat excluded dirs as conflicting if the changed file falls inside them)

### Step 3 — Apply non-conflicting changes

For each file in the clean changes list:
- New upstream file → copy to local plugin directory
- Modified upstream file → overwrite local copy
- File deleted upstream → delete from local (confirm with user before deleting)

Do not copy files or directories covered by `excluded` or `removed` customizations.

### Step 4 — Handle conflicts

For each conflicting file, present a side-by-side resolution:

```
CONFLICT: skills/brainstorming/SKILL.md
  Customization: custom-12 — "Reduced trigger sensitivity to complex requirements only"
  Reason: "Original trigger was too aggressive, activating on simple requests"

  LOCAL VERSION (your customized copy):
  ─────────────────────────────────────
  [show relevant lines]

  UPSTREAM VERSION (v5.1.0):
  ─────────────────────────────────────
  [show relevant lines]

  Options:
    (k) keep local — preserve your customization as-is
    (u) use upstream — overwrite with upstream version (removes customization)
    (m) manual merge — open both versions, you merge by hand
```

Ask the user for their choice for each conflict before proceeding.

### Step 5 — Reset option

If the user wants to discard all customizations and take upstream verbatim:
1. Delete everything in the local plugin directory (except `.claude-plugin/customizations.json` and `.claude-plugin/plugin.json`)
2. Copy all upstream files (respecting the `path` subpath if set)
3. Clear `customizations[]` to an empty array
4. Update `origin` tracking fields (see Step 6)
5. Warn the user: "All customizations discarded. Re-apply any needed changes manually."

Only do this if the user explicitly requests a reset.

### Step 6 — Update tracking

After applying changes, update `customizations.json`:

```json
{
  "origin": {
    "ref": "v5.1.0",
    "commit": "<new commit sha>",
    "fetched_at": "2026-03-31"
  },
  "upstream_status": {
    "last_checked": "2026-03-31",
    "latest_ref": "v5.1.0",
    "latest_commit": "<new commit sha>",
    "has_updates": false,
    "summary": "",
    "changes": []
  }
}
```

For conflicting files where the user chose "keep local", leave the customization entry unchanged. For conflicts where the user chose "use upstream", remove that customization entry from `customizations[]`.

Validate the file after editing:
```bash
python3 -m json.tool plugins/{name}/.claude-plugin/customizations.json
```

### Step 7 — Cleanup and commit

Remove the temp directory:
```bash
rm -rf /tmp/upstream-{plugin-name}
```

Stage the changed plugin files and updated customizations.json, then commit:
```
feat({plugin-name}): update to {new-ref} from {old-ref}
```

---

## Multi-Origin Plugins

For plugins that use `origins` (array) instead of `origin` (singular), such as forge-extended-dev:

### Checking

Check each origin independently using the method for its `ref` type. Present results grouped by plugin, with each origin on its own line:

```
forge-extended-dev (3 origins)
  anthropics/claude-code @ plugins/feature-dev (main)
    Latest commit: abc1234 (2026-04-10) — "Add async tool support"
    ⚡ Updates available — 3 commits since fetch
    ⚠ commands/feature-dev.md — conflicts with custom-03 (modified: superpowers handoff)

  anthropics/claude-code @ plugins/pr-review-toolkit (main)
    Latest commit: abc1234 (2026-04-10) — "Add async tool support"
    ✓ Up to date

  anthropics/claude-code @ plugins/code-review (main)
    Latest commit: abc1234 (2026-04-10) — "Add async tool support"
    ✓ Up to date
```

### Applying

When applying updates for a multi-origin plugin, handle each origin separately:
- Clone once per repo (not once per origin) — if multiple origins share a repo, one clone suffices
- Apply changes from each subpath independently
- Handle conflicts per-origin

Multi-origin customization entries have an `"origin"` field (e.g., `"origin": "feature-dev"`) that identifies which source they apply to. Use this field when doing conflict analysis — only cross-reference a customization against changes from its named origin, not all origins.

For the apply flow (Steps 1-7), repeat Steps 1-4 per origin, then do Steps 5-7 once for the whole plugin.
