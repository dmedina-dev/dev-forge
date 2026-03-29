# Dev Forge

Personal plugin marketplace for Claude Code. Curated collection of independent
plugins — install all or pick what you need.

## Quick start

```bash
# Add marketplace (once per machine)
/plugin marketplace add dmedina-dev/dev-forge

# Install what you need
/plugin install forge-keeper        # context maintenance (recommended always-on)
/plugin install forge-superpowers   # TDD, debugging, collaboration patterns
/plugin install forge-extended-dev  # discovery → design → deep review → PR review
/plugin install forge-security      # security reminder hooks
/plugin install forge-commit        # commit/PR commands
/plugin install forge-hookify       # custom hook rules engine
/plugin install forge-ralph         # persistent loop technique
/plugin install forge-plugin-dev    # plugin development toolkit (install when needed)
/plugin install forge-init          # project bootstrapper (uninstall after use)
```

## Available plugins

### Native plugins

Built from scratch for this marketplace.

| Plugin | Purpose | Lifecycle |
|--------|---------|-----------|
| **forge-init** | Project bootstrapper: `/init` interview + conventions layer + code exemplars | Disposable — uninstall after use |
| **forge-keeper** | Context maintenance: `/sync`, `/status`, `/optimize` + context watcher hook | Permanent — keeps CLAUDE.md and docs in sync |

### Core workflow

| Plugin | Purpose | Commands |
|--------|---------|----------|
| **forge-superpowers** | TDD, debugging, parallel agents, code review, worktrees, plans | Skills-based (auto-triggered) |
| **forge-extended-dev** | 4-phase development workflow (requires forge-superpowers) | `/feature-dev`, `/deep-review`, `/pr-review` |

#### Extended dev workflow

```
Phase A: /feature-dev        → Discovery, exploration, architecture design
Phase B: superpowers          → TDD planning, execution, intermediate reviews
Phase C: /deep-review [args]  → 5 specialized agents (tests, errors, types, comments, simplify)
Phase D: /pr-review [PR]      → Automated PR review: bugs + CLAUDE.md compliance
```

Phase D posts inline GitHub comments with `--comment` flag. Without the `github_inline_comment` MCP server, falls back to a single `gh pr comment`.

### Utility plugins

| Plugin | Purpose | Commands |
|--------|---------|----------|
| **forge-commit** | Git commit and PR workflow | `/commit`, `/commit-push-pr`, `/clean-gone` |
| **forge-security** | Security reminder hooks (XSS, injection, eval, pickle, etc.) | Passive — hooks on Edit/Write |
| **forge-hookify** | Custom hook rules engine with `.local.md` rules | `/hookify`, `/list`, `/configure`, `/help` |
| **forge-ralph** | Persistent loop: Claude keeps working across stop events | `/ralph-loop`, `/cancel-ralph`, `/help` |
| **forge-plugin-dev** | Plugin development toolkit: skills, agents, commands, hooks, MCP | `/create-plugin` |

## Plugin independence

- Every plugin works standalone — test with `claude --plugin-dir plugins/<name>`
- Only hard dependency: **forge-extended-dev requires forge-superpowers**
- Dependencies documented in `docs/dependencies.md`
- Remove any plugin to free context window space

## Attribution

Curated plugins retain their original authorship. No claim of original authorship is made for curated content.

### [obra/superpowers](https://github.com/obra/superpowers)

Original author: **Jesse Vincent** ([@obra](https://github.com/obra))

| Plugin | Upstream | Version |
|--------|----------|---------|
| forge-superpowers | [superpowers](https://github.com/obra/superpowers) | v5.0.6 |

### [anthropics/claude-code](https://github.com/anthropics/claude-code)

| Plugin | Original plugin | Original author |
|--------|----------------|-----------------|
| forge-plugin-dev | [plugin-dev](https://github.com/anthropics/claude-code/tree/main/plugins/plugin-dev) | Anthropic |
| forge-extended-dev | [feature-dev](https://github.com/anthropics/claude-code/tree/main/plugins/feature-dev) + [pr-review-toolkit](https://github.com/anthropics/claude-code/tree/main/plugins/pr-review-toolkit) + [code-review](https://github.com/anthropics/claude-code/tree/main/plugins/code-review) | Daisy Hollman, Boris Cherny (Anthropic) |
| forge-hookify | [hookify](https://github.com/anthropics/claude-code/tree/main/plugins/hookify) | Daisy Hollman (Anthropic) |
| forge-security | [security-guidance](https://github.com/anthropics/claude-code/tree/main/plugins/security-guidance) | Anthropic |
| forge-commit | [commit-commands](https://github.com/anthropics/claude-code/tree/main/plugins/commit-commands) | Anthropic |
| forge-ralph | [ralph-wiggum](https://github.com/anthropics/claude-code/tree/main/plugins/ralph-wiggum) | Anthropic |

### Customizations

All curated plugins include a `.claude-plugin/customizations.json` documenting every change from upstream:

- **excluded** — upstream file not included (e.g., duplicate code-reviewers)
- **removed** — content stripped (e.g., Anthropic-internal references)
- **modified** — content adapted (e.g., Python imports, workflow integration)
- **added** — new content (e.g., workflow documentation skill)

See `docs/customizations-pattern.md` for the full pattern.

## License

MIT
