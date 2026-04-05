# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Dev Forge

Personal plugin marketplace for Claude Code. Curated collection of independent plugins that can be installed individually or all at once.

## Architecture

Each plugin is **independent** — install, test, remove any plugin without affecting others. The marketplace is the catalog, not a bundle.

```
dev-forge/
├── .claude-plugin/marketplace.json    ← catalog of all available plugins
├── .upstream/                         ← persistent upstream clones (gitignored)
├── plugins/
│   ├── forge-init/                    ← bootstrapper (disposable)
│   ├── forge-keeper/                  ← context maintenance
│   ├── forge-superpowers/             ← core skills (curated from obra/superpowers)
│   ├── forge-plugin-dev/              ← plugin development toolkit
│   ├── forge-extended-dev/            ← extended workflow (requires forge-superpowers)
│   ├── forge-hookify/                 ← custom hook rules engine
│   ├── forge-security/                ← security reminder hooks
│   ├── forge-commit/                  ← commit/PR commands + marketplace release
│   ├── forge-ralph/                   ← persistent loop technique
│   ├── forge-frontend-design/         ← frontend UI/UX design
│   ├── forge-ui-expert/               ← UI/UX design intelligence (7 skills)
│   ├── forge-channels-telegram/       ← Telegram channel bridge (MCP, requires Bun)
│   ├── forge-proactive-qa/            ← autonomous QA agent (requires Playwright)
│   ├── forge-context-mcp/             ← MCP server setup guide (disposable)
│   ├── forge-export/                  ← marketplace export wizard (disposable)
│   ├── forge-brainstorming/           ← teammate-driven lifecycle (requires forge-superpowers)
│   └── forge-profiles/               ← plugin profile manager (independent)
└── docs/
    ├── dependencies.md                ← dependency map between plugins
    └── customizations-pattern.md      ← vendor + customizations pattern
```

## Plugin independence

- Every plugin works standalone — no implicit dependencies
- If a plugin REQUIRES another, document it in `dependencies.md`
- Testing with/without a plugin: `claude --plugin-dir plugins/<name>`
- Install all: install every plugin from the marketplace
- Install subset: pick only what you need

## When to unify vs separate

**Separate** (default): skills, agents, commands that make sense alone
**Unified** (exception): when a hook + skill + agent form a cohesive unit that breaks without each other (e.g., forge-keeper's context-watch hook + sync skill)

## Curation workflow

1. Find useful skill/agent/hook (superpowers, anthropic, custom)
2. Create independent plugin in `plugins/<name>/`
3. Note origin in SKILL.md if curated from external source
4. For external plugins: create `customizations.json` (see `docs/customizations-pattern.md`)
5. Add to marketplace.json
6. Test independently: `claude --plugin-dir plugins/<name>`
7. Push — available for installation

## External plugin customizations

External plugins follow a **vendor + customizations** pattern — see @docs/customizations-pattern.md for the full schema and update workflow. Native plugins (forge-init, forge-keeper, forge-proactive-qa, forge-brainstorming, forge-profiles) don't need customizations.json.

## Conventions

- SKILL.md frontmatter: `name` and `description` required
- Command .md frontmatter: `description` required
- Reference files: plain markdown, no frontmatter
- Hook scripts: `${CLAUDE_PLUGIN_ROOT}` for paths, always exit 0
- JSON: validate with `python3 -m json.tool`
- Skills from external sources: note origin in a comment at top of SKILL.md

## Commands

```bash
# Test any plugin independently
claude --plugin-dir plugins/<name>

# Test multiple together
claude --plugin-dir plugins/forge-init --plugin-dir plugins/forge-keeper
```

## Dependencies

Hard dependencies: **forge-extended-dev** and **forge-brainstorming** both require **forge-superpowers**. Full matrix in @docs/dependencies.md.

## Exemplars

Reference plugins for how things should be done — see @docs/exemplars.md.

## Gotchas

- marketplace.json `source.url` must use https (not git@) for public access
- Plugin directories need `.claude-plugin/plugin.json` to be recognized
- Skills trigger based on description text — vague descriptions = unreliable triggers
- When updating from upstream, use `/update-check` which syncs via `.upstream/` persistent clones (top-down: copy upstream → apply customizations)
- Custom `added` files in customizations.json MUST be documented or rsync `--delete` will remove them during sync
- `/release` command only works in marketplace repos (requires `.claude-plugin/marketplace.json`)
- context-watch.sh uses `trap 'exit 0' ERR` instead of `set -e` for safety
- forge-channels-telegram requires Bun runtime and Claude Code v2.1.80+ with channels support
- forge-proactive-qa requires Playwright installed in the target project
