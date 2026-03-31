# Dev Forge

Personal plugin marketplace for Claude Code. Curated collection of independent
plugins — install all or pick what you need.

## Quick start

```bash
# Add marketplace (once per machine)
/plugin marketplace add dmedina-dev/dev-forge

# Install all working plugins at once
/plugin install forge-init
/forge-init:install-all

# Or install individually
/plugin install forge-keeper        # context maintenance (recommended always-on)
/plugin install forge-superpowers   # TDD, debugging, collaboration patterns
/plugin install forge-extended-dev  # discovery → design → deep review → PR review
/plugin install forge-security      # security reminder hooks
/plugin install forge-commit        # commit/PR commands
/plugin install forge-hookify       # custom hook rules engine
/plugin install forge-ralph         # persistent loop technique
/plugin install forge-frontend-design # distinctive UI/UX design
/plugin install forge-channels-telegram # Telegram channel bridge (requires Bun)
```

## Working plugins

Always-on plugins for daily development.

### Native

| Plugin | Purpose | Commands |
|--------|---------|----------|
| **forge-keeper** | Context maintenance + PreCompact hook | `/sync`, `/status`, `/recall`, `/segment-doc` |

forge-keeper commands:
- `/sync` — analyze changes, propose CLAUDE.md + rules + exemplars updates
- `/status` — context health report with drift detection
- `/recall` — search session log for past decisions
- `/segment-doc` — split monolithic .md into focused pieces for better context loading

### Core workflow

| Plugin | Purpose | Commands |
|--------|---------|----------|
| **forge-superpowers** | TDD, debugging, parallel agents, code review, worktrees, plans | Skills-based (auto-triggered) |
| **forge-extended-dev** | 4-phase development workflow (requires forge-superpowers) | `/feature-dev`, `/deep-review`, `/pr-review` |

### Utility

| Plugin | Purpose | Commands |
|--------|---------|----------|
| **forge-commit** | Git commit and PR workflow | `/commit`, `/commit-push-pr`, `/clean-gone`, `/release` |
| **forge-security** | Security reminder hooks (XSS, injection, eval, etc.) | Passive — hooks on Edit/Write |
| **forge-hookify** | Custom hook rules engine with `.local.md` rules | `/hookify`, `/hookify-list`, `/hookify-configure`, `/hookify-help` |
| **forge-ralph** | Persistent loop: Claude keeps working across stop events | `/ralph-loop`, `/cancel-ralph`, `/ralph-help` |
| **forge-frontend-design** | Distinctive, production-grade UI/UX design | Skill-based (auto-triggered) |
| **forge-ui-expert** | UI/UX design intelligence: 67 styles, 96 palettes, 57 font pairings, 13 stacks | Skill-based (auto-triggered) |

### Channels

| Plugin | Purpose | Commands |
|--------|---------|----------|
| **forge-channels-telegram** | Telegram bridge — push messages into running session, reply from Claude | Skills: `telegram:configure`, `telegram:access` (auto-triggered) |

## Configuration plugins

Install when needed, uninstall after. Don't consume context when not in use.

| Plugin | Purpose | When to install |
|--------|---------|-----------------|
| **forge-init** | Project bootstrapper + install-all | New project: `/forge-init:init` then `/forge-init:install-all` then uninstall |
| **forge-plugin-dev** | Plugin development toolkit (7 skills, 3 agents) | Developing plugins: `/create-plugin` then uninstall |

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

### [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official)

| Plugin | Original plugin | Original author |
|--------|----------------|-----------------|
| forge-frontend-design | [frontend-design](https://github.com/anthropics/claude-plugins-official) | Prithvi Rajasekaran, Alexander Bricken (Anthropic) |
| forge-channels-telegram | [telegram](https://github.com/anthropics/claude-plugins-official/tree/main/external_plugins/telegram) | Anthropic |

### [nextlevelbuilder/ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill)

| Plugin | Original plugin | Original author |
|--------|----------------|-----------------|
| forge-ui-expert | [ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) | NextLevelBuilder |

### Customizations

All curated plugins include a `.claude-plugin/customizations.json` documenting every change from upstream:

- **excluded** — upstream file not included (e.g., duplicate code-reviewers)
- **removed** — content stripped (e.g., Anthropic-internal references)
- **modified** — content adapted (e.g., Python imports, workflow integration)
- **added** — new content (e.g., workflow documentation skill)

See `docs/customizations-pattern.md` for the full pattern.

## License

MIT
