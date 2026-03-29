---
name: forge-keeper
description: >
  Keeps CLAUDE.md and project documentation in sync. Suggest /forge-keeper:sync
  ONLY when the conversation crosses a clear boundary between unrelated concerns
  — for example the user was working on authentication and now asks about a
  payments bug, or finished backend API work and jumps to frontend UI, or shifts
  from infrastructure/DevOps to application code. Also suggest sync after major
  architectural decisions that affect project-wide conventions (e.g., changing
  testing strategy from mocks to testcontainers).
  DO NOT suggest sync when: the user continues the same task across multiple
  files (adding a field to model + DTO + migration is ONE feature), applies the
  same pattern to a different service (refactoring Strategy in PaymentService
  then NotificationService), does deep work within a single domain, verifies
  or tests work just completed, or makes trivial fixes like typos.
  Activates explicitly with /forge-keeper:sync, or when the user says "update
  context", "sync docs", "session handoff", or "save progress".
---

# Forge Keeper

Keeps project context synchronized across Claude Code sessions.

## When to run

- When you detect the conversation shifting between different domains or zones
- When the human explicitly requests it
- After the context-aware hook reminder (safety net)
- At the end of long sessions or before `/compact`
- After significant architectural decisions

## Execution model

**Run sync as a subagent or teammate** to avoid polluting the user's working
context. The analysis happens in an isolated context. Only the structured
proposal returns to the main conversation for review.

- **Subagent** (default) — dispatch via Agent tool with the sync steps
- **Teammate** — if configured, dispatch as named teammate for parallel execution

The user sees only: brief announcement → structured proposal → confirmation.

## Sync process (7 steps)

For detailed criteria on each step, read the corresponding references.

1. **Analyze changes** — `git diff --name-only` to identify files, classify by zone
2. **Propose CLAUDE.md updates** — per zone, respecting limits.
   See `references/claudemd-guide.md`
3. **Propose .claude/rules/** — if new cross-cutting conventions emerged
4. **Evaluate code exemplars** — if `docs/exemplars.md` exists, check if
   exemplars are still the best reference. See `references/exemplar-evaluation.md`
5. **Check project docs** — `docs/`, `README.md`, `docs/adr/`
6. **Generate session summary** — `docs/sessions/YYYY-MM-DD-title.md`
7. **Present structured proposal** — categorized by action type.
   See `references/proposal-format.md`

**DO NOT apply changes without explicit human confirmation.**
After approval, run `${CLAUDE_PLUGIN_ROOT}/scripts/reset-watch.sh`.

## Optimize (deep restructuring)

`/forge-keeper:optimize` — full audit of project fuel against current engine
capabilities. Use after plugin updates or when project config feels outdated.
Unlike sync (incremental, session-based), optimize does a deep restructuring.
See `references/optimize-process.md` for the full procedure.

## References

- CLAUDE.md maintenance → `references/claudemd-guide.md`
- Monorepo patterns → `references/monorepo-patterns.md`
- Exemplar evaluation → `references/exemplar-evaluation.md`
- Proposal format → `references/proposal-format.md`
- Optimize process → `references/optimize-process.md`
- Knowledge layer principles → `references/knowledge-principles.md`
