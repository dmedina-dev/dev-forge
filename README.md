# Dev Forge

Personal plugin marketplace for Claude Code. Curated collection of independent
plugins — install all or pick what you need.

## How it works

Each plugin is **independent**. Install one, install all, remove any — nothing breaks.

```bash
# Add marketplace (once per machine)
/plugin marketplace add dmedina-dev/dev-forge

# Install what you need
/plugin install forge-keeper        # context maintenance
/plugin install forge-superpowers   # TDD, debugging, collaboration patterns
/plugin install forge-extended-dev  # discovery + design + deep review
/plugin install forge-hookify       # custom hook rules engine
/plugin install forge-security      # security reminder hooks
/plugin install forge-commit        # commit/PR commands
/plugin install forge-ralph         # persistent loop technique
# ... pick and choose
```

## Available plugins

### Native plugins

Built from scratch for this marketplace.

| Plugin | Purpose | Lifecycle |
|--------|---------|-----------|
| **forge-init** | Project bootstrapper: `/init` interview + conventions layer | Disposable |
| **forge-keeper** | Context maintenance: `/sync`, `/status`, `/optimize` + context watcher hook | Permanent |

### Curated from [obra/superpowers](https://github.com/obra/superpowers)

Original author: **Jesse Vincent** ([@obra](https://github.com/obra))

| Plugin | Purpose | Upstream ref |
|--------|---------|-------------|
| **forge-superpowers** | Core skills: TDD, debugging, collaboration patterns, parallel agents, code review, worktrees | v5.0.6 |

### Curated from [anthropics/claude-code](https://github.com/anthropics/claude-code)

| Plugin | Original plugin | Original author | Upstream ref |
|--------|----------------|-----------------|-------------|
| **forge-plugin-dev** | [plugin-dev](https://github.com/anthropics/claude-code/tree/main/plugins/plugin-dev) | Anthropic | main |
| **forge-extended-dev** | [feature-dev](https://github.com/anthropics/claude-code/tree/main/plugins/feature-dev) + [pr-review-toolkit](https://github.com/anthropics/claude-code/tree/main/plugins/pr-review-toolkit) + [code-review](https://github.com/anthropics/claude-code/tree/main/plugins/code-review) | Daisy Hollman, Boris Cherny (Anthropic) | main |
| **forge-hookify** | [hookify](https://github.com/anthropics/claude-code/tree/main/plugins/hookify) | Daisy Hollman (Anthropic) | main |
| **forge-security** | [security-guidance](https://github.com/anthropics/claude-code/tree/main/plugins/security-guidance) | Anthropic | main |
| **forge-commit** | [commit-commands](https://github.com/anthropics/claude-code/tree/main/plugins/commit-commands) | Anthropic | main |
| **forge-ralph** | [ralph-wiggum](https://github.com/anthropics/claude-code/tree/main/plugins/ralph-wiggum) | Anthropic | main |

All curated plugins include a `customizations.json` documenting what was changed from upstream and why.

## Customizations

Curated plugins follow a **vendor + customizations** pattern:

- Each plugin's `.claude-plugin/customizations.json` tracks origin, applied changes, and upstream status
- Customization types: `excluded` (file not included), `removed` (content stripped), `modified` (content changed), `added` (new content)
- Upstream updates can be diffed against local customizations before merging

For details see `docs/customizations-pattern.md`.

## Plugin independence

- Every plugin works standalone — test with `claude --plugin-dir plugins/<name>`
- Dependencies documented in `docs/dependencies.md`
- Only one hard dependency: forge-extended-dev requires forge-superpowers
- Remove any plugin to free context window space

## Quick start

```bash
# Project bootstrapping
/plugin install forge-init
/forge-init:init          # interviews you, layers conventions
# then uninstall forge-init

# Ongoing development
/plugin install forge-keeper
/plugin install forge-superpowers
/forge-keeper:sync        # capture session changes
```

## License & Attribution

This marketplace is MIT licensed. Curated plugins retain their original licenses and authorship. The `customizations.json` in each plugin documents the original source and all modifications made. No claim of original authorship is made for curated content.
