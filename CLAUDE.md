# Dev Forge

Plugin marketplace for Claude Code. Plugins provide procedures, projects provide knowledge.

## Architecture

Monorepo with two plugins embedded via `git-subdir` source:
- `plugins/forge-init/` — disposable bootstrapper (use once, uninstall)
- `plugins/forge-keeper/` — permanent context maintenance

Each plugin is self-contained: `.claude-plugin/plugin.json`, `skills/`, `commands/`, and optionally `hooks/` + `scripts/`.

## Plugin anatomy

```
plugins/<name>/
├── .claude-plugin/plugin.json    ← manifest (name, version, description, author)
├── skills/<name>/
│   ├── SKILL.md                  ← main skill (YAML frontmatter: name, description)
│   └── references/               ← guides Claude reads on demand
├── commands/                     ← slash commands (YAML frontmatter: description)
├── hooks/hooks.json              ← optional: event hooks
└── scripts/                      ← optional: hook scripts
```

## Commands

```bash
# Test a plugin locally
claude --plugin-dir plugins/forge-init
claude --plugin-dir plugins/forge-keeper

# Test both
claude --plugin-dir plugins/forge-init --plugin-dir plugins/forge-keeper
```

## Conventions

- SKILL.md frontmatter MUST have `name` and `description` — description includes trigger phrases
- Command .md frontmatter MUST have `description`
- Reference files are plain markdown (no frontmatter) — read by the skill on demand
- Hook scripts use `${CLAUDE_PLUGIN_ROOT}` for path resolution
- Hook scripts must never block Claude Code — always exit 0
- All JSON validated with `python3 -m json.tool`
- marketplace.json uses `git-subdir` source pointing to `plugins/<name>`

## Adding a new plugin

1. Create `plugins/<name>/.claude-plugin/plugin.json`
2. Create `plugins/<name>/skills/<name>/SKILL.md` with triggers in description
3. Add references under `skills/<name>/references/` if needed
4. Add commands under `commands/` if needed
5. Add entry to `.claude-plugin/marketplace.json` plugins array
6. Update README.md
7. Test with `claude --plugin-dir plugins/<name>`

## Gotchas

- marketplace.json `source.url` must use https (not git@) for public access
- Plugin directories need `.claude-plugin/plugin.json` to be recognized
- Skills trigger based on description text — vague descriptions = unreliable triggers
- forge-keeper's semantic trigger will be refined with skill-creator evals
- context-watch.sh uses `trap 'exit 0' ERR` instead of `set -e` for safety
