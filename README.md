# Dev Forge

Personal plugin marketplace for Claude Code. Curated collection of independent
plugins — install all or pick what you need.

## How it works

Each plugin is **independent**. Install one, install all, remove any — nothing breaks.

```bash
# Add marketplace (once per machine)
/plugin marketplace add dmedina-dev/dev-forge

# Install what you need
/plugin install forge-keeper     # context maintenance
/plugin install forge-init       # project bootstrapper (uninstall after use)
/plugin install forge-agents     # work agents (example)
/plugin install forge-tdd        # TDD workflow
# ... pick and choose
```

## Available plugins

| Plugin | Purpose | Source | Lifecycle |
|--------|---------|--------|-----------|
| **forge-keeper** | Context maintenance: `/sync`, `/status`, `/optimize` + context watcher hook | Custom | Permanent |
| **forge-init** | Project bootstrapper: `/init` interview + conventions layer + code exemplars | Custom | Disposable |

*More plugins coming as skills are curated from superpowers, anthropic official, and custom sources.*

## Plugin independence

- Every plugin works standalone — test with `claude --plugin-dir plugins/<name>`
- Dependencies documented in `docs/dependencies.md`
- Install everything or just what you need
- Remove a plugin to test workflow without it

## For project bootstrapping

```bash
/plugin install forge-init
/forge-init:init          # interviews you, layers conventions
# then uninstall forge-init

/plugin install forge-keeper
/forge-keeper:status      # check context health
/forge-keeper:sync        # capture session changes
/forge-keeper:optimize    # deep restructuring after updates
```

## Configuration (forge-keeper)

| Variable | Default | Description |
|----------|---------|-------------|
| `FK_MIN_FILES` | 20 | Changed files before hook reminder |
| `FK_MIN_ZONES` | 3 | Zones touched before hook reminder |
| `FK_COOLDOWN` | 15 | Prompts between reminders |

## Curating new plugins

```bash
# 1. Create plugin structure
mkdir -p plugins/<name>/.claude-plugin
mkdir -p plugins/<name>/skills/<name>/references

# 2. Add plugin.json, SKILL.md, references
# 3. Add to .claude-plugin/marketplace.json
# 4. Test: claude --plugin-dir plugins/<name>
# 5. Document dependencies in docs/dependencies.md
# 6. Push
```

## License

MIT
