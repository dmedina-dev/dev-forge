---
name: forge-keeper
description: >
  Keeps CLAUDE.md, project documentation and memories in sync after development
  sessions. This skill should activate when detecting semantic context shifts:
  the conversation moves between different domain areas (e.g., from auth to
  payments), shifts from frontend to backend or across monorepo zones, makes
  significant architectural decisions, or accumulates substantial changes that
  haven't been captured in project context. Also activates with explicit
  /forge-keeper:sync. Use when the user mentions "update context", "sync docs",
  "refresh CLAUDE.md", "session handoff", "save progress", or when you detect
  the conversation has drifted across multiple concerns without a sync.
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
