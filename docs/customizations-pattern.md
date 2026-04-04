# External Plugin Customizations Pattern

## Overview

When incorporating external plugins into dev-forge, we follow a **vendor + customizations** pattern:

1. **Track origin** — record where the plugin came from (repo, version, commit)
2. **Document customizations** — every change applied on top of the original
3. **Detect upstream changes** — check for new versions and summarize what changed
4. **Merge safely** — reconcile upstream updates with local customizations

## Why

External plugins evolve independently. We need to:
- Know exactly what we changed and why
- Detect when upstream releases new versions
- Decide whether to update (summary of changes)
- Merge updates without losing our customizations

## customizations.json schema

Each external plugin has a `customizations.json` in its `.claude-plugin/` directory:

```json
{
  "origin": {
    "type": "github",
    "repo": "owner/repo-name",
    "path": "plugins/plugin-name",
    "ref": "v1.0.0",
    "commit": "abc1234def5678",
    "fetched_at": "2026-03-29",
    "check_url": "https://github.com/owner/repo-name/releases"
  },
  "upstream_status": {
    "last_checked": "2026-03-29",
    "latest_ref": "v1.0.0",
    "latest_commit": "abc1234def5678",
    "has_updates": false,
    "summary": "",
    "changes": []
  },
  "customizations": [
    {
      "id": "custom-01",
      "type": "removed",
      "target": "skills/some-skill/",
      "summary": "Removed skill — using alternative",
      "reason": "Replaced by Anthropic official skill-creator"
    },
    {
      "id": "custom-02",
      "type": "modified",
      "target": "skills/other-skill/SKILL.md",
      "summary": "Reduced trigger sensitivity",
      "reason": "Original trigger was too aggressive, activating on simple requests"
    },
    {
      "id": "custom-03",
      "type": "excluded",
      "target": "tests/",
      "summary": "Excluded ecosystem test infrastructure",
      "reason": "Only relevant to the upstream project's CI, not to our usage"
    }
  ]
}
```

### Field reference

#### `origin`

| Field | Description |
|-------|-------------|
| `type` | Source type: `github` |
| `repo` | Repository in `owner/name` format |
| `path` | Path within the repo (empty string if root) |
| `ref` | Git ref (tag, branch) used at fetch time |
| `commit` | Exact commit SHA for reproducibility |
| `fetched_at` | Date when the plugin was fetched |
| `check_url` | URL to check for new releases |

#### `upstream_status`

| Field | Description |
|-------|-------------|
| `last_checked` | Date of last update check |
| `latest_ref` | Most recent upstream ref found |
| `latest_commit` | Most recent upstream commit found |
| `has_updates` | Boolean: are there newer versions? |
| `summary` | One-line summary of available updates |
| `changes[]` | Detailed list of upstream changes since our version |

Each entry in `changes[]`:

```json
{
  "ref": "v2.0.0",
  "date": "2026-04-15",
  "summary": "Added multi-model support and fixed hook timeouts",
  "files_changed": ["hooks/hooks.json", "skills/agents/SKILL.md"],
  "conflicts_with_customizations": ["hooks/hooks.json"]
}
```

#### `customizations[]`

| Field | Description |
|-------|-------------|
| `id` | Unique identifier (custom-NN) |
| `type` | `removed` \| `modified` \| `excluded` \| `added` |
| `target` | File or directory affected (relative to plugin root) |
| `summary` | What was changed |
| `reason` | Why — intent behind the customization |

### Customization types

- **`excluded`** — upstream content not included (tests, CI, other platform configs)
- **`removed`** — upstream content deliberately deleted (unwanted skills, features)
- **`modified`** — upstream content changed (trigger adjustments, config tweaks)
- **`added`** — new content not in upstream (custom scripts, extra references)

## Update check flow

### Quick check: "Are there updates?"

```
forge-superpowers: ⚡ 2 releases ahead (v5.0.6 → v5.1.0)
  "Inline self-review + brainstorm server improvements"
  ⚠ 1 conflict with your customizations (skills/brainstorming/SKILL.md)
```

### Detailed check: "What changed?"

```
v5.1.0 (2026-04-15): Inline self-review replacing subagent loops
  Files: skills/brainstorming/SKILL.md, hooks/hooks.json
  ⚠ skills/brainstorming/SKILL.md — you modified the trigger (custom-02)
  ✓ hooks/hooks.json — no conflicts

v5.0.7 (2026-04-01): Bug fixes for session-start hook
  Files: hooks/session-start
  ✓ No conflicts with your customizations
```

### Update decision: "Apply update"

Uses persistent full clones in `.upstream/` (gitignored, one clone per upstream repo).

1. Ensure `.upstream/{repo-slug}/` exists (clone if first time, fetch if cached)
2. Checkout target ref, get precise upstream diff via `git diff {old}..{new}`
3. Cross-reference changed files against `customizations[]`
4. For clean changes (no customization match): copy from `.upstream/` to local
5. For conflicts (upstream changed a `modified` file): show upstream diff + local version + customization intent for resolution
6. Update `origin.ref`, `origin.commit`, `origin.fetched_at`
7. Update `upstream_status`

## Native plugins

Plugins created in-house (forge-init, forge-keeper) do NOT need customizations.json — they are the source of truth.
