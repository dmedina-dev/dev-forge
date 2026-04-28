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
/plugin install forge-keeper          # context maintenance (recommended always-on)
/plugin install forge-superpowers     # TDD, debugging, collaboration patterns
/plugin install forge-deep-review     # specialized review agents + automated PR review
/plugin install forge-brainstorming   # teammate-driven full lifecycle (requires forge-superpowers)
/plugin install forge-security        # security reminder hooks
/plugin install forge-commit          # commit/PR commands
/plugin install forge-hookify         # custom hook rules engine
/plugin install forge-profiles        # plugin profile manager
/plugin install forge-frontend-design # distinctive UI/UX design
/plugin install forge-ui-forge        # iterative UI prototyping with per-project registry
/plugin install forge-telegram        # Telegram listener + sender (bash + Monitor)
/plugin install forge-proactive-qa    # autonomous Playwright QA agent (Telegram-notified)
/plugin install forge-mattpocock      # alternative skills framework (mattpocock/skills)
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
| **forge-mattpocock** | Alternative skills framework: grill / to-prd (waves) / tdd / diagnose / improve-architecture / zoom-out / caveman. Coexists with forge-superpowers | Skills-based (auto-triggered) |
| **forge-deep-review** | Specialized review agents (tests, errors, types, comments, simplification) + automated PR review with inline GitHub comments | `/deep-review`, `/pr-review` |
| **forge-brainstorming** | Teammate-driven full lifecycle with 5 persistent agents (requires forge-superpowers) | `/brainstorming` |

### Utility

| Plugin | Purpose | Commands |
|--------|---------|----------|
| **forge-commit** | Git commit and PR workflow | `/commit`, `/commit-push-pr`, `/clean-gone`, `/release` |
| **forge-security** | Security reminder hooks (XSS, injection, eval, etc.) | Passive — hooks on Edit/Write |
| **forge-hookify** | Custom hook rules engine with `.local.md` rules | `/hookify`, `/hookify-list`, `/hookify-configure`, `/hookify-help` |
| **forge-profiles** | Plugin profile manager — switch plugins + MCP servers per work mode | `/profile-create`, `/profile-list`, `/profile-change` |

### Design & prototyping

| Plugin | Purpose | Commands |
|--------|---------|----------|
| **forge-frontend-design** | Distinctive, production-grade UI/UX design | Skill-based (auto-triggered) |
| **forge-ui-forge** | Iterative UI prototyping: generates N HTML screen variations, click-to-annotate via overlay, hot-reload regenerates from feedback. Outputs framework-agnostic specs + per-project component registry under `.ui-forge/` | Skill + `serve`, `stop`, `status`, `refresh` subcommands |

### Channels & autonomous agents

| Plugin | Purpose | Commands |
|--------|---------|----------|
| **forge-telegram** | Telegram bridge — Monitor-tool long-poll listener + manual send + Whisper voice transcription. Events arrive as turns in the main session | `/telegram start`, `/telegram stop`, `/telegram setup`, `/telegram status`, `/telegram send` |
| **forge-proactive-qa** | Autonomous Playwright QA agent — explores web apps, logs issues, auto-fixes with retry. Channel-first Telegram notifications. Three modes: explore / autofix / cycle | `/proactive-qa explore`, `/proactive-qa autofix`, `/proactive-qa cycle`, `/proactive-qa:init` |

## Configuration plugins

Install when needed, uninstall after. Don't consume context when not in use.

| Plugin | Purpose | When to install |
|--------|---------|-----------------|
| **forge-init** | Project bootstrapper + install-all + AGENTS.md generation | New project: `/forge-init:init` then `/forge-init:install-all` then uninstall |
| **forge-plugin-dev** | Plugin development toolkit (7 skills, 3 agents) | Developing plugins: `/create-plugin` then uninstall |
| **forge-context-mcp** | MCP server setup guide (Context7, Serena, XRAY) | Setting up codebase intelligence: configure servers then uninstall |
| **forge-export** | Exports dev-forge into a standalone marketplace repo — interview-driven, applies customizations | Forking a curated subset for another org/project then uninstall |

## Plugin independence

- Every plugin works standalone — test with `claude --plugin-dir plugins/<name>`
- Hard dependency: **forge-brainstorming** requires **forge-superpowers**
- Soft dependency: **forge-proactive-qa** integrates with **forge-telegram** for notifications (works without it)
- Dependencies documented in `docs/dependencies.md`
- Remove any plugin to free context window space

## Upgrading

The marketplace is versioned (`metadata.version` in `marketplace.json`) and so is each plugin. **A version bump invalidates the consumer's plugin cache.** Read [`CHANGELOG.md`](CHANGELOG.md) before upgrading — it lists every release with a `Migration` block when a plugin was renamed, removed, or changed in a breaking way.

**To pull the latest catalog into a session:**

```
/reload-plugins
```

This re-reads `marketplace.json` and reloads any plugin whose version is already cached at the same number. **It does not pull a *newer* version**: that requires the `/plugin` UI flow (`/plugin update <name>`) or a fresh session.

**For breaking changes** (a plugin you had installed was removed or renamed — for example the v2.0.0 prune of `forge-executor` / `forge-ui-expert` / `forge-ralph` and the rename `forge-extended-dev` → `forge-deep-review`):

1. Check `CHANGELOG.md` for the matching `## v{X.Y.Z}` section and follow the `Migration` steps.
2. `/plugin uninstall <old-name>` — removes the cached plugin you no longer use.
3. `/plugin install <new-name>` — installs the replacement, if any.
4. Replace any pinned slash-commands in your scripts/aliases (the changelog lists the new command paths).

**Pinning a known-good version:** use a git tag in your local marketplace clone if you maintain one (`git checkout v2.0.0 -- .claude-plugin/marketplace.json`). The marketplace itself does not currently support per-install version pinning via the `/plugin` UI; if you need to roll back, downgrade the whole marketplace ref.

**When new versions ship:**
- `MAJOR` plugin bumps mean breaking changes — read the `CHANGELOG.md` migration section before upgrading.
- `MINOR` bumps add features without breaking anything — safe to update at your convenience.
- `PATCH` bumps are bug or doc fixes — safe to update.

The full bump policy lives in [`docs/versioning.md`](docs/versioning.md).

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
| forge-deep-review | [pr-review-toolkit](https://github.com/anthropics/claude-code/tree/main/plugins/pr-review-toolkit) + [code-review](https://github.com/anthropics/claude-code/tree/main/plugins/code-review) | Daisy Hollman, Boris Cherny (Anthropic) |
| forge-hookify | [hookify](https://github.com/anthropics/claude-code/tree/main/plugins/hookify) | Daisy Hollman (Anthropic) |
| forge-security | [security-guidance](https://github.com/anthropics/claude-code/tree/main/plugins/security-guidance) | Anthropic |
| forge-commit | [commit-commands](https://github.com/anthropics/claude-code/tree/main/plugins/commit-commands) | Anthropic |

### [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official)

| Plugin | Original plugin | Original author |
|--------|----------------|-----------------|
| forge-frontend-design | [frontend-design](https://github.com/anthropics/claude-plugins-official) | Prithvi Rajasekaran, Alexander Bricken (Anthropic) |

### [mattpocock/skills](https://github.com/mattpocock/skills)

Original author: **Matt Pocock** ([@mattpocock](https://github.com/mattpocock))

| Plugin | Upstream | Pinned ref |
|--------|----------|------------|
| forge-mattpocock | [skills](https://github.com/mattpocock/skills) | main @ b56795b |

### Customizations

All curated plugins include a `.claude-plugin/customizations.json` documenting every change from upstream:

- **excluded** — upstream file not included (e.g., duplicate code-reviewers)
- **removed** — content stripped (e.g., Anthropic-internal references)
- **modified** — content adapted (e.g., Python imports, workflow integration)
- **added** — new content (e.g., workflow documentation skill)

See `docs/customizations-pattern.md` for the full pattern.

## License

MIT
