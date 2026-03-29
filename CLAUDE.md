# Dev Forge

Personal plugin marketplace for Claude Code. Curated collection of independent plugins that can be installed individually or all at once.

## Architecture

Each plugin is **independent** — install, test, remove any plugin without affecting others. The marketplace is the catalog, not a bundle.

```
dev-forge/
├── .claude-plugin/marketplace.json    ← catalog of all available plugins
├── plugins/
│   ├── forge-init/                    ← bootstrapper (disposable)
│   ├── forge-keeper/                  ← context maintenance
│   ├── forge-superpowers/             ← core skills (curated from obra/superpowers)
│   ├── forge-plugin-dev/              ← plugin development toolkit (curated from anthropics/claude-code)
│   ├── forge-extended-dev/            ← extended workflow: discovery + design + deep review (requires forge-superpowers)
│   └── ...                            ← each plugin independent
└── docs/
    ├── dependencies.md                ← dependency map between plugins
    └── customizations-pattern.md      ← vendor + customizations pattern for external plugins
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

External plugins follow a **vendor + customizations** pattern (see `docs/customizations-pattern.md`):

- `customizations.json` in `.claude-plugin/` tracks origin, applied changes, and upstream status
- Each customization has an id, type (`excluded`/`removed`/`modified`/`added`), and reason
- Upstream updates can be checked, summarized, and merged respecting local customizations
- Native plugins (forge-init, forge-keeper) don't need customizations.json

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

## Gotchas

- marketplace.json `source.url` must use https (not git@) for public access
- Plugin directories need `.claude-plugin/plugin.json` to be recognized
- Skills trigger based on description text — vague descriptions = unreliable triggers
- When updating from upstream (superpowers, anthropic), diff against your customizations
- context-watch.sh uses `trap 'exit 0' ERR` instead of `set -e` for safety
