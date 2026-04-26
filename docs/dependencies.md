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

### forge-deep-review
- **Independent** — specialized review agents + automated PR review
- Curated from anthropics/claude-code: pr-review-toolkit (specialized review agents) + code-review (automated PR review)
- 2 commands: /deep-review (5 specialized agents), /pr-review (automated GitHub PR review with inline comments)
- 5 agents: comment-analyzer, pr-test-analyzer, silent-failure-hunter, type-design-analyzer, code-simplifier
- Customizations: excluded duplicate code-reviewers, generalized Anthropic internals, dropped feature-dev workflow (use superpowers brainstorming + writing-plans)
- Complements forge-superpowers (run /deep-review after superpowers TDD execution)

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

### forge-telegram
- **Independent** — Telegram listener + sender, works standalone
- Native plugin (no upstream) — bash scripts + Haiku teammate using the `Monitor` tool
- 1 skill: /telegram (start/stop/setup/status/send dispatcher)
- 1 agent: telegram-listener (Haiku teammate that wraps listen.sh under Monitor and re-arms indefinitely)
- 4 scripts: setup.sh (PIN pairing), listen.sh (long-poll getUpdates), send.sh (outbound), transcribe.sh (Whisper helper)
- Credentials at ~/.claude/channels/telegram/.env (chmod 0600): TELEGRAM_BOT_TOKEN, AUTHORIZED_CHAT_ID, optional OPENAI_API_KEY
- Voice transcription inline in listen.sh via OpenAI Whisper — teammate only sees text events
- Requires the `Monitor` tool (Claude Code Apr 2026+), curl, jq, openssl. macOS: coreutils for gstdbuf.

### forge-proactive-qa
- **Independent** — autonomous QA agent, works standalone
- 1 skill: /proactive-qa (explore/autofix/cycle modes)
- 3 reference docs: explore flow, autofix flow, explore checklist
- 4 scripts: commit.sh (pre-approved), cleanup-explore.sh, cleanup-tmpdir.sh, telegram-notify.sh
- Notifications via direct curl (telegram-notify.sh). Credentials resolved from forge-telegram's ~/.claude/channels/telegram/.env (AUTHORIZED_CHAT_ID) with project .env as legacy fallback.
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

### forge-brainstorming
- **Requires forge-superpowers** — provides writing-plans, TDD, verification, finishing, worktrees
- Native plugin — full-lifecycle teammate orchestration with 5 persistent agents
- 1 command: /brainstorming (6-phase flow with 4 gates)
- 5 agents: scout (sonnet), architect (opus), builder (inherit), reviewer (inherit), closer (inherit)
- 1 skill: brainstorming-workflow (trigger + reference docs)
- Complements forge-superpowers:brainstorming (user chooses between persistent teammates or inline single-turn ideation)
- Complements forge-commit (closer can use /commit-push-pr if available)

### forge-profiles
- **Independent** — standalone plugin profile manager, no dependencies
- Manages ALL plugins and MCP servers, not just forge plugins
- 3 commands: /profile-create, /profile-list, /profile-change
- Profiles stored in .claude/settings.local.json (gitignored, personal)

## Current plugin matrix

```
Plugin                    Requires            Complements             Independent of
──────────────────────────────────────────────────────────────────────────────────
forge-init                -                   forge-keeper            everything else
forge-keeper              -                   forge-init              everything else
forge-superpowers         -                   forge-keeper            everything else
forge-plugin-dev          -                   -                       everything else
forge-deep-review         -                   forge-superpowers       everything else
forge-hookify             -                   -                       everything else
forge-security            -                   -                       everything else
forge-commit              -                   -                       everything else
forge-frontend-design     -                   -                       everything else
forge-telegram            -                   -                       everything else
forge-proactive-qa        -                   forge-telegram, /loop   everything else
forge-export              -                   -                       everything else
forge-context-mcp         -                   -                       everything else
forge-brainstorming       forge-superpowers   forge-commit            everything else
forge-profiles            -                   -                       everything else
```

## Rules for dependencies

1. **Default is independent** — design plugins to work alone
2. **If you need another plugin**, document it here AND in the plugin's SKILL.md description
3. **Complements** are soft — mention in docs but don't enforce
4. **Requires** are hard — plugin should warn at activation if dependency is missing
