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

### forge-frontend-design
- **Independent** — frontend design skill, works standalone
- Curated from anthropics/claude-plugins-official (frontend-design)
- Skill-based: triggers automatically on UI/UX design tasks, focused on distinctive, production-grade aesthetics over generic AI defaults
- Complements forge-ui-forge (design philosophy + iterative HTML prototyping form a natural pair, but each works alone)

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

### forge-mattpocock
- **Independent** — alternative skills framework, works standalone
- Curated from mattpocock/skills (pinned at HEAD of main, no upstream tags)
- 8 skills: grill-me, grill-with-docs, to-prd, tdd, diagnose, improve-codebase-architecture, zoom-out, caveman
- Adaptations: grill-with-docs and improve-codebase-architecture rewired to forge-keeper docs structure (CLAUDE.md / .claude/rules/ / docs/glossary.md / docs/adr/); to-prd outputs wave-organized plans to docs/plans/ (no GitHub assignment); zoom-out and caveman are unmodified
- Excluded by design (justifications in customizations.json): triage / to-issues (issue-tracker workflows), write-a-skill (overlaps with skill-creator), git-guardrails (overlaps with forge-security + forge-hookify), setup-pre-commit (JS-only), migrate-to-shoehorn / scaffold-exercises (niche)
- Coexists with forge-superpowers (no skill-name collisions). Side-by-side alternative to compare

### forge-ui-forge
- **Independent** — UI prototyping toolkit, works standalone
- Native plugin (no upstream)
- 1 skill + subcommands: serve, stop, status, refresh
- Iterative HTML screen variations, click-to-annotate overlay (point pins on click, area selection on Shift+drag), hot-reload dev server with 🚀 Send to Claude and SSE auto-reload, per-project registry of reusable components and fixtures under `.ui-forge/`
- Live mode that proxies an existing dev server and injects the overlay (opt-in, requires aiohttp)
- Produces framework-agnostic specs for downstream implementation
- Complements forge-frontend-design (philosophy + prototyping form a natural pair)

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
forge-mattpocock          -                   forge-keeper            everything else
forge-ui-forge            -                   forge-frontend-design   everything else
```

## Rules for dependencies

1. **Default is independent** — design plugins to work alone
2. **If you need another plugin**, document it here AND in the plugin's SKILL.md description
3. **Complements** are soft — mention in docs but don't enforce
4. **Requires** are hard — plugin should warn at activation if dependency is missing

## marketplace.json schema fields used by dev-forge

### `dependencies` (array of plugin names) — **native Claude Code field**

Lists hard dependencies. **Must be a flat array of strings** — Claude Code's marketplace schema validator rejects any other shape (object, nested) with `Invalid input: expected array, received object` and refuses to load the marketplace. Mirrors the **requires** column in the matrix above.

```json
{
  "name": "forge-brainstorming",
  "version": "1.0.1",
  "dependencies": ["forge-superpowers"]
}
```

> **History:** v2.1.1 introduced this field as `{"required": [...]}` (object form, treating it as a dev-forge custom extension). Claude Code's UI rejected the marketplace at install time. v2.2.1 corrected to the flat-array form. If you add a hard dependency, keep the **requires** column in the matrix above in sync.

### `writes_outside_project_root` (array of paths) — **dev-forge extension**

Lists paths the plugin writes to OUTSIDE the consumer's project root — typically `~/.claude/channels/<plugin>/`. Surfaces in the install flow so the consumer knows:

1. The path may need to be added to `sandbox.filesystem.allowWrite` in `.claude/settings.local.json` (the project's CLAUDE.md gotcha section explains why).
2. On uninstall, the consumer should manually delete the directory to clean up state and credentials.

```json
{
  "name": "forge-telegram",
  "version": "1.2.0",
  "writes_outside_project_root": [
    "~/.claude/channels/telegram/"
  ]
}
```

Plugins that only read (not write) external paths do NOT declare this — declaring it implies state ownership.

This field is a dev-forge-specific extension; Claude Code's schema validator ignores unknown fields, so it's safe. (The `dependencies` field is NOT one of those — it's a reserved name with a strict shape, learnt the hard way at v2.2.1.)
