---
name: forge-init
description: >
  Project bootstrapper for Claude Code. Runs the native /init interview, then
  layers opinionated conventions: CLAUDE.md quality audit, per-directory context
  files, path-scoped rules, @import wiring for existing docs, code exemplars,
  and documentation scaffolding. Use when bootstrapping a new project, adding
  Claude Code to an existing project, or when the user mentions "initialize",
  "bootstrap", "setup project", "forge init". Uninstall after use.
---

# Forge Init

Guided bootstrapper: runs /init then layers conventions on top.

## Step 1 — Run native /init

Guide the human to run:

```
/init
```

This interviews the developer and generates base configuration (CLAUDE.md,
skills, hooks, `.claude/`).

## Step 2 — Conventions layer

Audit what /init produced and layer on top. For detailed criteria, read
`references/claudemd-conventions.md`.

1. **Audit CLAUDE.md quality** — ~200 line limit, WHY/WHAT/HOW structure,
   specific and verifiable instructions, no linter rule duplication
2. **Fill per-directory gaps** — CLAUDE.md for zones /init missed (~100 lines
   each, supplement root, don't repeat)
3. **Connect existing development guides** — scan for DEVELOPMENT.md,
   CONTRIBUTING.md, and per-directory guides. Add as @imports in the
   corresponding CLAUDE.md so Claude loads them automatically per zone.
   See `references/claudemd-conventions.md` § "Connect existing development guides".
4. **Add path-scoped rules** — `.claude/rules/` with globs for cross-cutting
   conventions (testing, security, style)
5. **Documentation scaffolding** — `docs/sessions/` as personal session
   log (bitácora), `docs/adr/` with ADR template
6. **Code exemplars** — identify reference files with the human. Exemplars
   are pointers to actual files + lesson learned, not copies.
   See `references/code-exemplars.md` for the process.
7. **Initialization report** — `docs/sessions/YYYY-MM-DD-forge-init.md`
   documenting what was discovered, decided, and configured

Present complete summary to the human. **DO NOT write files until confirmed.**

## Step 3 — Self-cleanup

After approval:
```
To uninstall forge-init (no longer needed):
  /plugin → Manage and uninstall plugins → forge-init → Uninstall

forge-keeper is active for ongoing maintenance.
Run /forge-keeper:status to check context health anytime.
```

## References

- CLAUDE.md conventions → `references/claudemd-conventions.md`
- Code exemplars process → `references/code-exemplars.md`
- Knowledge layer principles → `references/knowledge-principles.md`
