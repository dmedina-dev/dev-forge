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
│   ├── forge-agents/                  ← work agents with model config (example)
│   ├── forge-tdd/                     ← TDD workflow (curated from superpowers)
│   └── ...                            ← each plugin independent
└── docs/
    └── dependencies.md                ← dependency map between plugins
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
4. Add to marketplace.json
5. Test independently: `claude --plugin-dir plugins/<name>`
6. Push — available for installation

## Conventions

- SKILL.md frontmatter: `name` and `description` required
- Command .md frontmatter: `description` required
- Reference files: plain markdown, no frontmatter
- Hook scripts: `${CLAUDE_PLUGIN_ROOT}` for paths, always exit 0
- JSON: validate with `python3 -m json.tool`
- Skills from external sources: note origin at top of SKILL.md
