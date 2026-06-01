---
allowed-tools: Bash(git:*), Bash(python3:*), Bash(rsync:*), Bash(cp:*), Bash(bash:*), Read, Edit, Write, Grep, Glob, AskUserQuestion
description: "Import an existing plugin (installed in ~/.claude, or a remote git repo) into this dev-forge marketplace: copy into plugins/, write customizations.json, register in marketplace.json, validate."
---

## Guard — dev-forge marketplace repo only

This command adopts an external plugin **into this marketplace**. It only makes sense in a
plugin marketplace repo. Check for `.claude-plugin/marketplace.json` at the repo root. If it
doesn't exist, stop:

> This command is for marketplace repos only. It requires `.claude-plugin/marketplace.json` at the repo root.

Do NOT proceed unless the file exists.

## Context

- Current marketplace plugins (collision check): !`python3 -c "import json; print(', '.join(sorted(p['name'] for p in json.load(open('.claude-plugin/marketplace.json'))['plugins'])))"`
- Marketplace source URL (for new entries): !`python3 -c "import json; ps=json.load(open('.claude-plugin/marketplace.json'))['plugins']; print(ps[0]['source']['url'] if ps else 'https://github.com/dmedina-dev/dev-forge.git')"`
- Installed plugins available to import (actually-installed, from other marketplaces): !`python3 -c "
import json, os
home = os.path.expanduser('~/.claude/plugins')
own = set()
try:
    own = {p['name'] for p in json.load(open('.claude-plugin/marketplace.json'))['plugins']}
except Exception: pass
try:
    km = json.load(open(os.path.join(home,'known_marketplaces.json')))
except Exception:
    km = {}
def repo_of(mkt):
    s = km.get(mkt, {}).get('source', {})
    return s.get('repo','?') if isinstance(s, dict) else '?'
try:
    inst = json.load(open(os.path.join(home,'installed_plugins.json'))).get('plugins', {})
except Exception:
    inst = {}
rows = []
for key, recs in sorted(inst.items()):
    if '@' not in key: continue
    name, mkt = key.rsplit('@', 1)
    if mkt == 'dev-forge' or name in own: continue
    rec = max(recs, key=lambda r: r.get('lastUpdated','')) if isinstance(recs, list) and recs else {}
    ver = rec.get('version','?'); sha = (rec.get('gitCommitSha','') or '')[:10]
    rows.append('  {}@{}  v{}  (repo {}{})'.format(name, mkt, ver, repo_of(mkt), '  '+sha if sha else ''))
print('\n'.join(rows) if rows else '  (none — only dev-forge plugins installed; use the git-repo source instead)')
"`

## Your task

Adopt one plugin into this marketplace. Walk the user through it; **all writes require explicit
approval before they happen.** Two source modes: **installed** (from ~/.claude above) or **git**
(a remote GitHub repo).

### Step 1 — Choose the source

Ask (AskUserQuestion) whether to import:
- **(a) an installed plugin** from the inventory in Context, or
- **(b) a remote git repo** (owner/repo, optional subpath, ref).

### Step 2a — Installed plugin source

1. Have the user pick a plugin from the Context inventory (`<name>@<marketplace>`).
2. **Files** — read the install record from
   `~/.claude/plugins/installed_plugins.json` (key `<name>@<marketplace>`, a list of installs).
   Use the most recent record's `installPath` (a `cache/<marketplace>/<name>/<version>/` dir) as
   the source tree — that is the real installed plugin, even for external/aggregator plugins whose
   files don't live under the marketplace clone. Verify it has `.claude-plugin/plugin.json`. The
   record's `gitCommitSha` is the precise `commit` for origin tracking.
3. **Origin** — read that marketplace's own
   `~/.claude/plugins/marketplaces/<marketplace>/.claude-plugin/marketplace.json`, find the entry
   for `<name>`, and recover the true upstream: its `upstream` block (`repo`, `ref`, `url`) if
   present, otherwise its `source` (an aggregator often points each entry at a different GitHub
   repo via `source.repo`/`source.url` — that repo, not the marketplace repo, is the real origin).
   If neither yields a GitHub source, treat the plugin as **native** and confirm with the user.

### Step 2b — Remote git source

1. Ask for `owner/repo`, an optional subpath within the repo (empty = repo root), and a ref
   (default `main`).
2. Clone or fetch into `.upstream/` (same convention as `/update-check`):
   ```bash
   SLUG=$(echo "{owner/repo}" | tr '/' '-')
   [ -d ".upstream/$SLUG" ] || git clone "https://github.com/{owner/repo}.git" ".upstream/$SLUG"
   git -C ".upstream/$SLUG" fetch --all --tags
   git -C ".upstream/$SLUG" checkout {ref}
   git -C ".upstream/$SLUG" pull 2>/dev/null || true
   ```
3. Source path = `.upstream/$SLUG/<subpath>/`. Verify it contains a `.claude-plugin/plugin.json`
   (a valid plugin). If not, stop and report — the subpath isn't a plugin root.
4. Record the exact commit: `git -C ".upstream/$SLUG" rev-parse {ref}`.

### Step 3 — Target name + collision check

- Propose a target name. dev-forge convention is `forge-<original>`; offer both `forge-<original>`
  and the original name, and let the user choose or type another.
- The target name MUST NOT already appear in the Context plugin list, and `plugins/<name>/` MUST
  NOT already exist. If either collides, stop and ask the user for a different name.

### Step 4 — Copy the plugin into plugins/

- Copy the resolved source tree to `plugins/<name>/`. Use `rsync -a` excluding junk:
  ```bash
  rsync -a --exclude '.git' --exclude 'node_modules' --exclude '.DS_Store' "<source>/" "plugins/<name>/"
  ```
- Offer to exclude upstream-only dirs the marketplace doesn't need (`tests/`, `.github/`, CI
  configs). Record each exclusion as an `excluded` customization in Step 5.
- Ensure `plugins/<name>/.claude-plugin/plugin.json` exists and its `name` field equals the
  target name. If `version` is missing, seed `0.1.0`. Edit precisely; do not rewrite the file.

### Step 5 — Write customizations.json

Create `plugins/<name>/.claude-plugin/customizations.json`.

**For an external (git/installed-with-upstream) plugin:**
```json
{
  "origin": {
    "type": "github",
    "repo": "<owner/repo>",
    "path": "<subpath or empty string>",
    "ref": "<ref>",
    "commit": "<sha from rev-parse, or upstream commit if known>",
    "fetched_at": "<today YYYY-MM-DD>",
    "check_url": "https://github.com/<owner/repo>/tree/<ref>/<subpath>"
  },
  "upstream_status": {
    "last_checked": "<today>",
    "latest_ref": "<ref>",
    "latest_commit": "<sha>",
    "has_updates": false,
    "summary": "",
    "changes": []
  },
  "customizations": [
    // one { "id": "custom-NN", "type": "excluded", "target": "...", "summary": "...", "reason": "..." }
    // per dir excluded in Step 4; [] if none
  ]
}
```
Get today's date by reading it from the environment context — do **not** call `date` if the
sandbox blocks it; the harness provides the current date.

**For a native (hand-authored, no upstream) plugin:**
```json
{
  "origin": { "type": "native", "note": "Imported local plugin; no upstream to track." }
}
```

Note the origin in the SKILL.md of any curated skill if it came from a known external source
(see `.claude/rules/plugin-authoring.md` for the attribution comment format) — but only if the
user confirms the provenance.

### Step 6 — Register in marketplace.json

Append a new entry to the `plugins` array. Match the existing entry shape exactly:
```json
{
  "name": "<name>",
  "description": "<one line — derive from plugin.json description; confirm with user>",
  "source": { "source": "git-subdir", "url": "<marketplace source URL from Context>", "path": "plugins/<name>" },
  "version": "<version from plugin.json>",
  "upstream": { "repo": "<owner/repo>", "ref": "<ref>", "url": "<check_url>" }
}
```
Omit the `upstream` block for native imports. Do **NOT** touch `metadata.version` — bumping the
marketplace version is `/release`'s job, done later when this import ships.

### Step 7 — Regenerate catalog docs

```bash
bash scripts/generate-install-all.sh
```
Then flag the doc-parity updates the sync rule expects (`.claude/rules/sync-keeps-docs-current.md`):
the README plugin table, the CLAUDE.md `## Architecture` tree, and `docs/dependencies.md`. Propose
the specific row/line additions and apply them only after the user approves — or tell the user to
run `/forge-keeper:sync` to handle the doc sweep.

### Step 8 — Validate

```bash
python3 -m json.tool .claude-plugin/marketplace.json >/dev/null
python3 -m json.tool plugins/<name>/.claude-plugin/customizations.json >/dev/null
python3 -m json.tool plugins/<name>/.claude-plugin/plugin.json >/dev/null
bash scripts/marketplace-health.sh
```
All must pass. If `marketplace-health.sh` fails, fix the reported issue before finishing.

### Step 9 — Summary

Print a concise summary:

```
📦 Imported <name> into dev-forge

   Source:   <installed: marketplace/name vX.Y.Z | git: owner/repo@ref subpath>
   Origin:   <github owner/repo @ ref (commit abc1234) | native>
   Added:    plugins/<name>/  +  marketplace.json entry  +  customizations.json
   Version:  <version> (starts here; /release bumps it when shipped)
   Docs:     install-all.md regenerated; README / CLAUDE.md tree updated (or: run /forge-keeper:sync)

   Next: review the diff, then /release to bump + tag, and /reload-plugins (or new session) to load it.
```

Do not run `/release` automatically — leave the version bump and tag to the user.
