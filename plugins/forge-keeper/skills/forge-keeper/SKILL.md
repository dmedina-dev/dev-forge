---
name: forge-keeper
description: >
  Keeps CLAUDE.md, rules, exemplars, and project documentation in sync.
  Activates explicitly with /forge-keeper:sync, or when the user says "update
  context", "sync docs", "session handoff", or "save progress". Also triggers
  automatically before /compact or /clear via hook, capturing context before
  it's lost.
context: fork
---

# Forge Keeper

Keeps project context synchronized across Claude Code sessions.

## When to run

- When the human explicitly requests sync
- Automatically before `/compact` or `/clear` (via PreCompact hook)
- At the end of long sessions
- After significant architectural decisions

## Execution model

Run sync in a **forked subagent** so the analysis inherits the current session's
context (it already "knows what we did") without polluting the user's working
conversation. Only the structured proposal returns to the main session.

- Preferred — `context: fork` in this skill's frontmatter (activates when
  Claude Code honors the field; tracked upstream in anthropics/claude-code#17283)
- Fallback while fork is not wired — run inline in the current session. Do NOT
  dispatch a regular (blank-context) subagent: it would need a full re-brief of
  the session and lose all nuance, defeating the point of sync.

The user sees only: brief announcement → structured proposal → confirmation.

## Sync process (6 steps)

For detailed criteria on each step, read the corresponding references.

1. **Analyze changes** — `git diff --name-only` to identify files, classify by zone
2. **Propose CLAUDE.md updates** — per zone, respecting limits.
   See `references/claudemd-guide.md`
3. **Propose .claude/rules/** — if new cross-cutting conventions emerged
4. **Evaluate code exemplars** — if `docs/exemplars.md` exists, check if
   exemplars are still the best reference. See `references/exemplar-evaluation.md`
5. **Check project docs** — `docs/`, `README.md`, `docs/adr/`
6. **Present structured proposal** — categorized by action type.
   See `references/proposal-format.md`

**DO NOT apply changes without explicit human confirmation.**

## Related commands

- `/forge-keeper:update-check` — check plugins for upstream updates and apply them

## References

- CLAUDE.md maintenance → `references/claudemd-guide.md`
- Monorepo patterns → `references/monorepo-patterns.md`
- Exemplar evaluation → `references/exemplar-evaluation.md`
- Proposal format → `references/proposal-format.md`
