# Gate Protocols

How the orchestrator (team lead) manages user interaction at each gate. Gates are checkpoints where user input is required before proceeding.

---

## General Gate Principles

1. **Present structured information** — use markdown tables, numbered lists, clear sections
2. **Ask specific questions** — not "what do you think?" but "which approach do you prefer: A, B, or C?"
3. **Offer early exit** — at every gate, remind the user they can stop here
4. **Handle delegation** — if user says "whatever you think is best", provide your recommendation AND get explicit confirmation
5. **Never skip mandatory gates** — Gates 1 and 2 always require user input

---

## Gate 1: Clarifying Questions (Mandatory)

**Trigger:** After scout completes all 3 exploration passes.

**What to present:**
1. Brief summary of scout's key findings (3-5 bullets)
2. Patterns discovered that are relevant to the feature
3. Organized list of clarifying questions, grouped by topic:
   - **Scope**: boundaries, what's in/out
   - **Behavior**: edge cases, error handling, validation rules
   - **Integration**: connections with existing features, backward compatibility
   - **Preferences**: UI/UX choices, naming, conventions
4. Any risks or constraints discovered

**Format:**
```markdown
## Codebase Exploration Complete

### Key Findings
- [finding 1]
- [finding 2]

### Relevant Patterns
- [pattern] — used in [where]

### Questions Before Design

**Scope:**
1. [question]
2. [question]

**Behavior:**
3. [question]

**Integration:**
4. [question]

### Early Exit Option
If you only needed the exploration, we can stop here. Otherwise, answer the
questions above and I'll proceed to architecture design.
```

**If user says "whatever you think":** Provide your recommended answers with reasoning, then ask: "Does this match your intent? I'll proceed with these assumptions unless you correct any."

---

## Gate 2: Architecture Choice (Mandatory)

**Trigger:** After architect presents all approaches.

**What to present:**
1. Brief comparison table of all approaches
2. Trade-offs for each (pros/cons)
3. Your recommendation with reasoning
4. Key differences in implementation effort

**Format:**
```markdown
## Architecture Approaches

| Aspect | A: Minimal | B: Clean | C: Pragmatic |
|--------|-----------|----------|--------------|
| Effort | Low       | High     | Medium       |
| Maintainability | Fair | Excellent | Good    |
| Risk   | Low       | Medium   | Low          |

### Approach A: [Name]
[1-2 sentence summary + key trade-off]

### Approach B: [Name]
[1-2 sentence summary + key trade-off]

### Approach C: [Name]
[1-2 sentence summary + key trade-off]

### My Recommendation
I recommend **Approach [X]** because [concrete reasoning based on this project's needs].

### Early Exit Option
If you have the architecture you need, we can stop here and you can implement
it yourself. Otherwise, pick an approach (or request refinement) and I'll create
the implementation plan.
```

**If user wants refinement:** Send the feedback to architect, architect refines, re-present.

**If user says "whatever you think":** State your choice clearly: "I'm going with Approach B because [reason]. Proceeding to planning." Wait for explicit confirmation.

---

## Gate 3: Plan Approval (Soft)

**Trigger:** After plan is written and reviewer validates the spec.

**Skip condition:** `--auto-plan` flag — auto-approve and proceed.

**What to present:**
1. Plan summary: number of tasks, estimated components, key technologies
2. Task list overview (titles only, not full details)
3. Reviewer's spec validation result (Approved or Issues + how they were resolved)

**Format:**
```markdown
## Implementation Plan Ready

**Plan file:** `docs/superpowers/plans/YYYY-MM-DD-{name}.md`
**Tasks:** {N} tasks following TDD
**Spec validation:** {Approved / Issues resolved}

### Task Overview
1. [Task 1 title]
2. [Task 2 title]
3. ...

### Early Exit Option
If you want to execute this plan yourself (via `/subagent-driven-development`
or `/executing-plans`), you can stop here. Otherwise, approve and I'll begin
TDD execution with builder + reviewer teammates.

Approve to proceed?
```

**If user wants changes:** Modify the plan, re-validate with reviewer, re-present.

---

## Gate 4: Review Findings (Conditional)

**Trigger:** After reviewer completes deep review (Phase 5).

**Auto-proceed conditions:**
- No critical or important issues found (only suggestions)
- In this case: mention the suggestions, offer to address them, but proceed to Phase 6

**Pause conditions:**
- Any critical or important issues found

**What to present:**
1. Deep review summary (from reviewer's aggregated output)
2. For critical/important issues: ask user how to handle
3. Options: fix now, defer to post-merge, dismiss with reason

**Format (issues found):**
```markdown
## Deep Review Results

### Critical Issues ({N})
- [issue] — [file:line]

### Important Issues ({N})
- [issue] — [file:line]

### Suggestions ({N})
- [suggestion] — [file:line]

### Options
1. **Fix critical + important now** — builder addresses them before PR (recommended)
2. **Fix critical only** — defer important to follow-up
3. **Proceed as-is** — acknowledge risks and continue to PR

Which option?
```

**Format (no issues):**
```markdown
## Deep Review Results

No critical or important issues found. {N} suggestions noted.

### Suggestions
- [suggestion] — [file:line]

Proceeding to PR phase. I can address suggestions if you'd like, or continue.
```

---

## Early Exit Handling

At any gate, if the user indicates they want to stop:

1. Summarize what was accomplished so far
2. Note any artifacts created (exploration findings, architecture docs, plans)
3. Suggest how to resume later if desired
4. Shutdown all active teammates
5. TeamDelete to clean up

**Format:**
```markdown
## Session Summary

### Completed
- [what was done]

### Artifacts
- [file path] — [what it contains]

### To Resume
[How to pick up from here — e.g., "Run `/brainstorming` again with the plan file,
or use `/subagent-driven-development` directly on the plan."]
```
