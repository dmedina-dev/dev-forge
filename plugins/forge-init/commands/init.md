---
description: Two-step project bootstrapper. Step 1: runs native /init interview for base config. Step 2: layers dev-forge conventions — CLAUDE.md improvements, path-scoped rules, docs scaffolding. Uninstall after use.
---

Run the forge-init skill to bootstrap this project for Claude Code.

This is a guided two-step process:

Step 1 — Foundation:
  Run the native /init with interview mode (CLAUDE_CODE_NEW_INIT=1).
  This scans your codebase and interviews you about workflows and preferences.

Step 2 — Conventions:
  Audit and improve /init's output with dev-forge best practices:
  - CLAUDE.md quality (200-line limit, WHY/WHAT/HOW structure)
  - Per-directory CLAUDE.md for zones /init may have missed
  - Path-scoped .claude/rules/ for cross-cutting conventions
  - Documentation scaffolding (docs/sessions/, docs/adr/)
  - Personal overrides file (CLAUDE.local.md)

All changes require your explicit approval before being applied.

After initialization, uninstall this plugin:
  /plugin → Manage and uninstall plugins → forge-init → Uninstall
