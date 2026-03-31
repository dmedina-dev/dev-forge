# Plugin Dependency Map

Which plugins depend on or complement each other.

## Legend

- **requires** — won't work without the other plugin
- **complements** — works better together but each is functional alone
- **independent** — no relationship

## Current plugins

### forge-init
- **Independent** — standalone bootstrapper, no dependencies
- Mentions forge-keeper in cleanup message but doesn't require it

### forge-keeper
- **Self-contained** — hooks + skills + scripts form a cohesive unit
- The context-watch hook, sync/status commands, and references are tightly coupled
- This is an example of justified unification: splitting hook from skill would break the workflow

### forge-superpowers
- **Independent** — core skills library, works standalone
- Curated from obra/superpowers v5.0.6 with customizations (see `.claude-plugin/customizations.json`)
- 12 skills: brainstorming, TDD, debugging, parallel agents, code review, worktrees, plans, etc.
- Skills reference each other internally but each works independently
- Complements forge-keeper (debugging/TDD workflows benefit from context maintenance)

### forge-plugin-dev
- **Independent** — plugin development toolkit, works standalone
- Curated from anthropics/claude-code (plugins/plugin-dev) with minimal customizations
- 7 skills: skill-development, agent-development, command-development, hook-development, mcp-integration, plugin-structure, plugin-settings
- 3 agents: agent-creator, plugin-validator, skill-reviewer
- 1 command: /create-plugin (8-phase guided workflow)
- Install when developing plugins, uninstall when done (heavy context footprint)

### forge-extended-dev
- **Requires forge-superpowers** — provides TDD execution, verification, debugging, git worktrees, finishing workflow
- Curated from anthropics/claude-code: feature-dev (discovery/design) + pr-review-toolkit (specialized review)
- 2 commands: /feature-dev (discovery → architecture → handoff), /deep-review (5 specialized agents)
- 7 agents: code-explorer, code-architect, comment-analyzer, pr-test-analyzer, silent-failure-hunter, type-design-analyzer, code-simplifier
- 1 skill: extended-dev-workflow (master flow documentation)
- Customizations: removed duplicate code-reviewers, generalized Anthropic internals
- Complements forge-keeper (context maintenance during extended workflows)

### forge-hookify
- **Independent** — custom hook rules engine, works standalone
- Curated from anthropics/claude-code (plugins/hookify) with import customizations
- 4 hook events: PreToolUse, PostToolUse, Stop, UserPromptSubmit
- 4 commands: /hookify (create rules), /hookify-list, /hookify-configure, /hookify-help
- 1 agent: conversation-analyzer
- 1 skill: writing-rules (rule format reference)

### forge-security
- **Independent** — security reminder hooks, works standalone
- Curated from anthropics/claude-code (plugins/security-guidance) with customizations
- PreToolUse hook checking 9 vulnerability patterns on Edit/Write/MultiEdit
- Session-scoped state to avoid repeat warnings

### forge-commit
- **Independent** — commit and PR commands, works standalone
- Curated from anthropics/claude-code (plugins/commit-commands) with customizations
- 3 commands: /commit (staged changes), /commit-push-pr (full flow), /clean-gone (branch cleanup)

### forge-ralph
- **Independent** — persistent loop technique, works standalone
- Curated from anthropics/claude-code (plugins/ralph-wiggum) with customizations
- Stop hook + setup script for self-referential loop
- 3 commands: /ralph-loop (start), /cancel-ralph (stop), /ralph-help

### forge-channels-telegram
- **Independent** — Telegram channel bridge, works standalone
- Curated from anthropics/claude-plugins-official (external_plugins/telegram) with security hardening
- MCP server: bridges Telegram Bot API to Claude Code session via channels protocol
- 2 skills: /telegram:access (pairing + allowlist management), /telegram:configure (token setup)
- 4 MCP tools: reply, react, download_attachment, edit_message
- Security customizations: fail-closed assertSendable, disabled-on-corrupt recovery, env var restriction, logged errors
- Requires Bun runtime and Claude Code v2.1.80+ with channels support

### forge-proactive-qa
- **Independent** — autonomous QA agent, works standalone
- 1 skill: /proactive-qa (explore/autofix/cycle modes)
- 3 reference docs: explore flow, autofix flow, explore checklist
- 4 scripts: commit.sh (pre-approved), cleanup-explore.sh, cleanup-tmpdir.sh, telegram-notify.sh (fallback)
- Channel-first notifications: uses forge-channels-telegram MCP reply tool when available, falls back to curl
- Designed for `/loop` (cycle mode alternates explore/autofix)
- Requires Playwright in target project

### forge-export
- **Independent** — standalone exporter, no dependencies
- Install on demand, uninstall after use (disposable like forge-init)

### forge-context-mcp
- **Independent** — MCP server setup guide, no dependencies
- Install on demand, uninstall after configuring servers (disposable)
- Guides: Context7 (library docs), Serena (LSP navigation), XRAY (structural analysis)
- MCP servers run independently from .claude/settings.json after setup

## Current plugin matrix

```
Plugin                    Requires            Complements         Independent of
──────────────────────────────────────────────────────────────────────────────────
forge-init                -                   forge-keeper        everything else
forge-keeper              -                   forge-init          everything else
forge-superpowers         -                   forge-keeper        everything else
forge-plugin-dev          -                   -                   everything else
forge-extended-dev        forge-superpowers   forge-keeper        everything else
forge-hookify             -                   -                   everything else
forge-security            -                   -                   everything else
forge-commit              -                   -                   everything else
forge-ralph               -                   -                   everything else
forge-frontend-design     -                   -                   everything else
forge-ui-expert           -                   forge-frontend-design everything else
forge-channels-telegram   -                   -                   everything else
forge-proactive-qa        -                   forge-channels-telegram, /loop  everything else
forge-export              -                   -                   everything else
forge-context-mcp         -                   -                   everything else
```

## Rules for dependencies

1. **Default is independent** — design plugins to work alone
2. **If you need another plugin**, document it here AND in the plugin's SKILL.md description
3. **Complements** are soft — mention in docs but don't enforce
4. **Requires** are hard — plugin should warn at activation if dependency is missing
