---
description: Deep restructuring of project context after plugin updates. Audits your CLAUDE.md, rules, and exemplars against current dev-forge capabilities and proposes upgrades. Use after /plugin marketplace update or when project config feels outdated.
---

Run the forge-keeper optimize process to align your project's context
configuration with the latest dev-forge capabilities.

This is different from /forge-keeper:sync (which captures session changes).
Optimize does a full audit of your project fuel against the current engine.

The process:
1. Detect what dev-forge version/features are available now
2. Audit existing project configuration against current capabilities
3. Identify gaps and improvement opportunities
4. Present a structured upgrade proposal
5. Apply only what you approve

Read `references/optimize-process.md` for the detailed procedure.

DO NOT apply changes without explicit human confirmation.
