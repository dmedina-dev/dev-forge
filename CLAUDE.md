# Dev Forge

Personal unified plugin for Claude Code. Single point of control for all skills, agents, hooks, and commands across all projects.

## Why this exists

Instead of installing multiple plugins (superpowers, skill-creator, custom skills) in each project, dev-forge curates everything in one place. Install once, get everything. Update here, all projects benefit.

## Architecture

Two-layer system:

**Marketplace** (`.claude-plugin/marketplace.json`) — distributes plugins via `git-subdir`:
- `plugins/forge-init/` — disposable bootstrapper for OTHER projects (install, bootstrap, uninstall)
- `plugins/forge-keeper/` — permanent plugin with curated skills, context maintenance, hooks

**Curation sources:**
- Superpowers (obra/superpowers) — workflow skills, adapted and personalized
- Anthropic official (skill-creator) — kept as-is or lightly adapted
- Custom — forge-keeper, forge-init, project-specific skills

## What goes where

- `plugins/forge-keeper/skills/` — all permanent skills (curated + custom)
- `plugins/forge-keeper/commands/` — slash commands
- `plugins/forge-keeper/hooks/` — event hooks
- `plugins/forge-keeper/agents/` — agent definitions
- `plugins/forge-init/` — bootstrapper only, separate lifecycle

## Workflow for curating skills

1. Identify a skill from superpowers, anthropic, or create new
2. Adapt to personal preferences (e.g., less strict brainstorming trigger)
3. Add to `plugins/forge-keeper/skills/<name>/`
4. Test with `claude --plugin-dir plugins/forge-keeper`
5. Commit and push — all projects get the update

## Conventions

- SKILL.md frontmatter: `name` and `description` required
- Command .md frontmatter: `description` required
- Reference files: plain markdown, no frontmatter
- Hook scripts: `${CLAUDE_PLUGIN_ROOT}` for paths, always exit 0
- JSON: validate with `python3 -m json.tool`
- Skills from external sources: note origin in a comment at top of SKILL.md

## Commands

```bash
# Test forge-keeper (the main plugin)
claude --plugin-dir plugins/forge-keeper

# Test forge-init (the bootstrapper)
claude --plugin-dir plugins/forge-init

# Test both together
claude --plugin-dir plugins/forge-init --plugin-dir plugins/forge-keeper
```

## Gotchas

- marketplace.json `source.url` must use https (not git@) for public access
- forge-keeper is the main plugin — all curated skills go here, not in separate plugins
- forge-init is intentionally separate because it's disposable (uninstall after use)
- When updating from upstream (superpowers, anthropic), diff against your customizations
- context-watch.sh uses `trap 'exit 0' ERR` for safety
