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
- When modifying marketplace.json, keep source URLs as https (not git@ssh)
- Skills curated from external sources (superpowers, anthropic) must note origin at top of SKILL.md
- When updating from upstream, diff against local customizations before overwriting
