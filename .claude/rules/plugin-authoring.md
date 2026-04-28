---
description: Conventions for authoring and modifying plugin files
globs: plugins/**
---

- SKILL.md must have YAML frontmatter with `name` and `description` fields
- Skill `description` must include trigger phrases — words/patterns that cause Claude to activate the skill
- Command .md files must have YAML frontmatter with `description` field
- Reference files are plain markdown without frontmatter
- All changes to plugin content must be tested with `claude --plugin-dir plugins/<name>`
- Hook scripts must use `${CLAUDE_PLUGIN_ROOT}` for paths, never relative paths
- Hook scripts must guarantee exit 0 — use `trap 'exit 0' ERR` or equivalent
- JSON files must validate with `python3 -m json.tool`
- Before pushing changes to `.claude-plugin/marketplace.json` or any plugin's `plugin.json`, run `bash scripts/marketplace-health.sh` — `python3 -m json.tool` only validates JSON syntax, not Claude Code's marketplace schema. The health script catches reserved-field shape errors (e.g. `dependencies` must be a flat array of strings, not an object — see CLAUDE.md gotcha), version drift between plugin.json and marketplace.json, missing plugin paths, broken dependency references, and stale `install-all.md`
- When modifying marketplace.json, keep source URLs as https (not git@ssh)
- Skills curated from external sources (superpowers, anthropic, mattpocock, etc.) must note origin at top of SKILL.md. Use a single-line HTML comment immediately after the YAML frontmatter, invisible in rendered markdown but searchable in source: `<!-- Curated from <repo>/<path> · <license>. <Unmodified | Adapted: <one-line summary>>. -->`. Established in forge-mattpocock (v2.3.0); reapply to any future external curation
- When updating from upstream, diff against local customizations before overwriting
- Long-running bash loops that use `set -uo pipefail` (omitting `-e` to survive transient errors) must preflight any file-backed state write at startup and exit loudly if it fails. Silent write failures otherwise cause stuck-state infinite loops. See `plugins/forge-telegram/scripts/listen.sh` `preflight_offset_write` for the template (write a sentinel, read it back, restore the original, fail fast with an actionable error)
- For small config files (single word, < 100 bytes), use direct writes (`printf '%s\n' "$v" > "$FILE"`) — not tmp-file-plus-rename. Writes under `PIPE_BUF` (4096 bytes) are atomic at the kernel level, and staging filenames like `file.tmp.NNNN` require their own sandbox allowlist entry without offering any real benefit at that size
- Plugins that write state outside the current project root (typically `~/.claude/channels/<plugin>/`) must document every writable file in the plugin's `references/operational.md` § sandbox section so consumers can add them to `sandbox.filesystem.allowWrite`. Never use `mktemp -t template` or `mktemp -p $TMPDIR` — always pass an explicit template path inside an already-allowlisted directory
