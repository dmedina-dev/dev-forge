---
name: to-prd
description: Synthesize the current conversation into a PRD-style plan organized by waves and save it to docs/plans/. Does NOT interview — just turns the existing context into an executable plan. Use when the user wants to crystallize the current discussion into a written, parallel-friendly plan they can dispatch to subagents or build on solo.
---

<!-- Curated from mattpocock/skills · skills/engineering/to-prd/SKILL.md · MIT. Adapted: removed all GitHub / issue-tracker assignment; output is a wave-organized plan saved to disk. -->

# To-PRD (waves)

Take the current conversation context and codebase understanding and produce a wave-organized plan. **Do NOT interview the user** — synthesize what you already know. If a critical piece is genuinely missing, stop and name it; don't fish for trivia.

## What "waves" means here

A **wave** is a group of tasks that can run in parallel — typically by independent subagents — because they share no dependencies. Waves run **sequentially**: the next wave starts only after the previous one is fully complete.

```
Wave 1: [task A] [task B]   ← run in parallel (no dependencies)
   ↓
Wave 2: [task C] [task D]   ← depend on Wave 1 outputs
   ↓
Wave 3: [task E]            ← integrates everything
```

Use waves when the work has natural cut-points — schema changes before backend logic, backend before frontend wiring, etc. Don't force a wave structure where the work is genuinely linear (one wave with one task per step is fine).

## Process

### 1. Re-orient on the codebase

Skim the repo to refresh your model of what exists. Use the project's domain language (from `docs/glossary.md` / CLAUDE.md / similar) consistently in the PRD. Respect existing ADRs in the area you're touching — surface conflicts explicitly, don't paper over them.

### 2. Decompose into modules

Sketch the modules you'll need to build or modify. Actively look for opportunities to extract **deep modules** (small interface, lots of implementation behind it) that can be tested in isolation.

Confirm with the user (one round, not an interview):

- Does this module decomposition match what you expect?
- Which modules need tests written?

If the user is AFK, proceed with your decomposition and note the assumption in the plan.

### 3. Group tasks into waves

Walk the decomposition and assign each task to a wave by dependency:

- **Wave 1** — anything that depends only on the existing code (data models, pure helpers, fixture builders).
- **Wave 2+** — anything that depends on Wave 1 outputs (services using the new models, handlers using the new services).
- **Final wave** — integration, end-to-end tests, docs, and any cleanup.

Within a wave, tasks must be **truly independent** — no shared files, no shared types being mutated by two tasks at once. If two tasks touch the same file, merge them into one task or push one to the next wave.

### 4. Write the plan

Save to `docs/plans/YYYY-MM-DD-<feature-slug>.md`. Use today's date (UTC) and a kebab-case slug derived from the feature name.

Use this template:

```md
# {Feature Name} Plan

**Goal:** {one sentence}
**Architecture:** {2–3 sentences about approach}
**Tech stack:** {key technologies / libraries}

---

## Problem statement

The problem the user is facing, from the user's perspective.

## Solution

The solution to the problem, from the user's perspective.

## User stories

A LONG, numbered list. Each story is "As a {actor}, I want {feature}, so that {benefit}".

1. As a mobile bank customer, I want to see my balance, so that I can make better-informed spending decisions.
2. ...

This list should be extensive — it pins down behavior the waves will deliver.

## Implementation decisions

- Modules to be built/modified, with their interfaces (signatures, not file paths)
- Architectural decisions
- Schema changes
- API contracts
- Specific interactions

Do **not** include file paths or code snippets — they go stale fast. The waves below carry the executable detail.

## Testing decisions

- What makes a good test here (test external behavior, not implementation)
- Which modules need tests
- Prior art in the codebase to follow

## Out of scope

What this plan does NOT do.

---

## Wave 1 — {short name}

**Runs in parallel.** All tasks in this wave have no dependencies between them.

### Task 1.1: {Name}

**Files:**
- Create: `src/path/to/file.ts`
- Test: `tests/path/to/test.ts`

- [ ] Step 1: Write the failing test
  ```ts
  // concrete test code
  ```
- [ ] Step 2: Run it and watch it fail
  ```
  pnpm test path/to/test.ts
  # Expected: FAIL — "function not defined"
  ```
- [ ] Step 3: Write minimal implementation
  ```ts
  // concrete implementation
  ```
- [ ] Step 4: Run it and watch it pass
- [ ] Step 5: Commit

### Task 1.2: {Name}

(same shape)

---

## Wave 2 — {short name}

**Depends on:** Wave 1 outputs ({list specific outputs}).

### Task 2.1: {Name}

(same shape)

---

## Wave N — Integration

End-to-end tests, docs updates, cleanup.

---

## Self-review checklist

- [ ] Every user story maps to at least one task
- [ ] No task has placeholders ("TBD", "implement later", "add error handling")
- [ ] Within each wave, tasks touch disjoint files
- [ ] Type and signature names are consistent across waves
- [ ] If two waves were swapped, the second wave would clearly fail — proves the dependency is real
```

### 5. Self-review

After writing, look at the plan with fresh eyes:

1. **Story coverage.** Skim each user story. Can you point to a task that delivers it? List gaps; add tasks if needed.
2. **Placeholder scan.** Search for "TBD", "implement later", "fill in", "add appropriate error handling", "add validation". Replace with actual content.
3. **Type / name consistency.** A function called `clearLayers()` in Task 2.1 but `clearFullLayers()` in Task 3.4 is a bug — fix it inline.
4. **Wave independence.** Within a wave, no two tasks should write to the same file. If they do, either merge them or push one to the next wave.
5. **Wave dependency reality.** If you swapped Waves N and N+1, would N+1 still work? If yes, the dependency you claimed isn't real — collapse them.

Fix issues inline; no need to re-review.

### 6. Hand off

```
Plan saved to docs/plans/YYYY-MM-DD-<slug>.md.

Suggested execution:
- Wave 1: dispatch {N} parallel subagents (one per task)
- Wave 2: dispatch {M} parallel subagents
- ...

Or execute inline, one wave at a time, reviewing between waves.

Want me to dispatch Wave 1 now, or are you reviewing the plan first?
```

## Anti-patterns

- **Don't** interview the user. Synthesize from context. (If you genuinely cannot, stop and name what's missing — don't fish.)
- **Don't** include file paths in the PRD section. Paths belong in tasks, not in implementation decisions.
- **Don't** organize by technical layer (all-frontend wave, all-backend wave). Organize by **dependency**. Two tasks on different layers can share a wave if they're independent.
- **Don't** create a wave per task just to look organized. A linear plan with one task per wave is a sign the work is genuinely sequential — that's fine, but you don't need waves for it.
- **Don't** schedule cleanup or docs as a parallel task to integration. They belong in the final wave, after integration confirms the system works.
