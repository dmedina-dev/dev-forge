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
- The context-watch hook, sync/status/optimize commands, and references are tightly coupled
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

## Current plugin matrix

```
Plugin              Requires            Complements         Independent of
──────────────────────────────────────────────────────────────────────────
forge-init          -                   forge-keeper        everything else
forge-keeper        -                   forge-init          everything else
forge-superpowers   -                   forge-keeper        everything else
forge-plugin-dev    -                   -                   everything else
forge-extended-dev  forge-superpowers   forge-keeper        everything else
```

## Rules for dependencies

1. **Default is independent** — design plugins to work alone
2. **If you need another plugin**, document it here AND in the plugin's SKILL.md description
3. **Complements** are soft — mention in docs but don't enforce
4. **Requires** are hard — plugin should warn at activation if dependency is missing
