---
name: forge-init
description: >
  Two-step project bootstrapper for Claude Code. Step 1 runs the native /init
  to interview the developer and generate base configuration. Step 2 layers
  opinionated conventions on top: CLAUDE.md quality improvements, per-directory
  context files, path-scoped rules, documentation scaffolding, and code exemplars.
  Use this skill when bootstrapping a new project, adding Claude Code support to
  an existing project, or when the user mentions "initialize", "bootstrap",
  "setup project", "forge init", or any variant that implies first-time
  configuration. This plugin is designed to be uninstalled after use.
---

# Forge Init

Two-step bootstrapper: native /init foundation + conventions layer.

## Step 1 — Run native /init

Guide the human to run:

```
CLAUDE_CODE_NEW_INIT=1 /init
```

This interviews the developer and generates base configuration (CLAUDE.md,
skills, hooks, `.claude/`).

If /init is unavailable, use the fallback in `references/manual-discovery.md`.

## Step 2 — Conventions layer

Audit what /init produced and layer on top. For detailed criteria, read
`references/claudemd-conventions.md`.

1. **Audit CLAUDE.md quality** — ~200 line limit, WHY/WHAT/HOW structure,
   specific and verifiable instructions, no linter rule duplication
2. **Fill per-directory gaps** — CLAUDE.md for zones /init missed (~100 lines
   each, supplement root, don't repeat)
3. **Add path-scoped rules** — `.claude/rules/` with globs for cross-cutting
   conventions (testing, security, style)
4. **Documentation scaffolding** — `docs/sessions/`, `docs/adr/` with template
5. **Personal overrides** — `CLAUDE.local.md` (gitignored)
6. **Code exemplars** — identify reference files with the human.
   See `references/code-exemplars.md` for the process.
7. **Initialization report** — `docs/sessions/YYYY-MM-DD-forge-init.md`

Present complete summary to the human. **DO NOT write files until confirmed.**

## Step 3 — Self-cleanup

After approval:
```
To uninstall forge-init (no longer needed):
  /plugin → Manage and uninstall plugins → forge-init → Uninstall

session-keeper is active for ongoing maintenance.
Run /session-keeper:status to check context health anytime.
```

## References

- CLAUDE.md conventions → `references/claudemd-conventions.md`
- Manual discovery fallback → `references/manual-discovery.md`
- Code exemplars process → `references/code-exemplars.md`
