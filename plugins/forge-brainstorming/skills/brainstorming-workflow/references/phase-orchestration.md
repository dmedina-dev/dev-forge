# Phase Orchestration Playbook

Detailed per-phase orchestration for the `/brainstorming` command. The orchestrator (team lead) follows this playbook to coordinate teammates, manage gates, and handle transitions.

## Teammate Lifecycle

| Phase | Spawn | Active | Shutdown |
|-------|-------|--------|----------|
| 1-Discovery | scout | scout | — |
| 2-Design | architect | scout, architect | — |
| 3-Planning | reviewer | reviewer | scout, architect |
| 4-Execution | builder | builder, reviewer | — |
| 5-Deep Review | — | reviewer | builder |
| 6-PR & Close | closer | closer | reviewer |

**Rule:** Only keep teammates alive when they're needed. Shutdown reduces context pressure.

---

## Phase 1: Discovery

### Setup
1. Create team: `TeamCreate(team_name: "brainstorming-{slug}")`
2. Create tasks for Phase 1
3. Spawn scout: `Agent(name: "scout", subagent_type: "forge-brainstorming:scout", team_name: "brainstorming-{slug}")`

### Message to Scout
```
Explore this codebase for a feature: {feature_description}

Perform 3 passes:

Pass 1 — Similar Features: Find existing features similar to this request. Trace
their implementation end-to-end. Identify reusable patterns.

Pass 2 — Architecture: Map the architecture, conventions, tech stack, and module
boundaries relevant to this feature area.

Pass 3 — Integration: Identify where this feature would connect. Find constraints,
dependencies, and potential conflicts. Check CLAUDE.md for guidelines.

For each pass, report: key findings, patterns discovered, 5-10 essential files,
risks or constraints.
```

### After Scout Reports
- Read the key files scout identified (orchestrator reads them directly)
- Compile clarifying questions from: scout's risks/constraints + orchestrator's own analysis
- Proceed to Gate 1

---

## Phase 2: Design

### Message to Architect
```
Design architecture for: {feature_description}

## Scout Findings
{paste scout's compiled findings from all 3 passes}

## User Requirements (from clarifying questions)
{paste user's answers to Gate 1 questions}

## Constraints
{constraints from CLAUDE.md, scout's risks, user's answers}

Design 2-3 genuinely different approaches:
- Approach A — Minimal: smallest change, maximum reuse
- Approach B — Clean Architecture: best maintainability
- Approach C — Pragmatic Balance: speed + quality

Include for each: rationale, trade-offs, component design with exact file paths,
implementation map, data flow, build sequence, risk assessment.
```

### After Architect Reports
- Review all approaches for completeness
- Form your own recommendation with reasoning
- Present to user: brief summary of each, trade-offs comparison, your recommendation
- Proceed to Gate 2

---

## Phase 3: Planning

### After User Chooses Approach
1. Announce: "I'm using the writing-plans skill to create the implementation plan."
2. Use superpowers:writing-plans to convert chosen architecture into TDD plan
   - Include: all context from Phases 1-2
   - Each task follows TDD: failing test → verify → implement → verify → commit
   - Save to: `docs/superpowers/plans/YYYY-MM-DD-{feature-name}.md`
3. Spawn reviewer (if not already active) for spec validation

### Message to Reviewer (Spec Validation)
```
MODE: spec-validation

Review this spec document for completeness and implementation readiness:
{spec_file_path}

Check: completeness, consistency, clarity, scope, YAGNI.
Only flag issues that would cause real problems during planning.
```

### After Reviewer Reports
- If issues found: address them in the plan, re-validate if needed
- Shutdown scout and architect: `SendMessage(to: "scout", message: {type: "shutdown_request"})` and same for architect
- Proceed to Gate 3

---

## Phase 4: Execution

### Setup
1. Set up git worktree: use superpowers:using-git-worktrees
2. Spawn builder: `Agent(name: "builder", subagent_type: "forge-brainstorming:builder", team_name: "brainstorming-{slug}")`
3. Ensure reviewer is active (spawned in Phase 3)

### Per-Task Loop

For each task in the plan:

**Step A — Dispatch to Builder:**
```
Implement Task {N}: {task_name}

## Task Description
{FULL TEXT of task from plan — paste it, don't make builder read file}

## Context
{architectural context, dependencies on previous tasks, relevant patterns}

## Working Directory
{worktree path}

## Protocol
Follow TDD: failing test → verify failure → implement → verify pass → commit.
Self-review before reporting. Report status: DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT.
```

**Step B — Handle Builder Response:**
- DONE → proceed to reviewer
- DONE_WITH_CONCERNS → read concerns, decide whether to proceed or address first
- NEEDS_CONTEXT → provide missing context, re-dispatch
- BLOCKED → assess: provide context, break task, or escalate to user

**Step C — Dispatch to Reviewer (Per-Task):**
```
MODE: per-task

Review Task {N}: {task_name}

## Requirements
{FULL TEXT of task spec}

## Builder's Report
{builder's report}

## Git Range
Base: {sha_before_task}
Head: {current_sha}

Stage 1: Spec compliance (Do Not Trust the Report — read the code).
Stage 2: Code quality (only if Stage 1 passes).
```

**Step D — Handle Reviewer Response:**
- If spec compliant + quality passes → mark task complete, next task
- If issues found → send issues to builder, builder fixes, re-review (loop)

### After All Tasks Complete
- Proceed to Phase 5

---

## Phase 5: Deep Review

### Message to Reviewer (Deep Mode)
```
MODE: deep-review

All {N} tasks are implemented. Run deep specialized review on the full implementation.

## Branch Info
Base branch: {main_branch}
Feature branch: {feature_branch}
Changed files: {list from git diff --name-only main...HEAD}

Apply all 5 lenses (dispatch as parallel sub-agents for speed):
1. Test Coverage
2. Silent Failures
3. Type Design
4. Comment Accuracy
5. Code Simplification

See references/review-lenses.md for detailed protocols per lens.
Aggregate results into Critical/Important/Suggestions format.
```

### After Reviewer Reports
- If critical or important issues found → Gate 4 (present to user)
- If only suggestions → auto-proceed (mention suggestions, offer to address)
- Shutdown builder: `SendMessage(to: "builder", message: {type: "shutdown_request"})`

---

## Phase 6: PR & Close

### Setup
1. Spawn closer: `Agent(name: "closer", subagent_type: "forge-brainstorming:closer", team_name: "brainstorming-{slug}")`

### Message to Closer
```
Implementation is complete and reviewed. Handle the closing phase.

## Feature
{feature_description}

## Branch
{feature_branch} based on {main_branch}

## Flags
--comment: {yes/no}
--skip-pr: {yes/no}

## Architecture Summary (for PR body)
{chosen approach summary from Phase 2}

Steps:
1. Run verification (all tests must pass)
2. Present finishing options to me (I'll relay to user)
3. Execute chosen option
4. If PR: run automated review pipeline
5. Report final status
```

### After Closer Reports
- Relay finishing options to user, relay choice back to closer
- After PR created: share PR URL with user
- After review complete: share findings
- Shutdown all remaining teammates
- TeamDelete to clean up

---

## Transition Criteria

| From → To | Condition |
|-----------|-----------|
| Phase 1 → Gate 1 | Scout completed all 3 passes |
| Gate 1 → Phase 2 | User answered clarifying questions |
| Phase 2 → Gate 2 | Architect presented all approaches |
| Gate 2 → Phase 3 | User chose an approach |
| Phase 3 → Gate 3 | Plan written + reviewer approved spec |
| Gate 3 → Phase 4 | User approved plan (or --auto-plan) |
| Phase 4 → Phase 5 | All tasks complete + pass review |
| Phase 5 → Gate 4 | Deep review complete |
| Gate 4 → Phase 6 | User addresses critical/important (or none found) |
| Phase 6 → Done | Closer reports final status |
