---
description: "Full-lifecycle development with persistent teammates — discovery, design, planning, TDD execution, deep review, and PR creation in one unified flow"
argument-hint: "[feature description] [--auto-plan] [--skip-pr] [--comment]"
---

# Brainstorming — Teammate-Driven Development Lifecycle

You are orchestrating a full development lifecycle for a complex feature using persistent teammates. Each teammate has a distinct role and accumulates context across phases.

**Feature request:** $ARGUMENTS

## Prerequisites

This workflow **requires forge-superpowers** plugin (provides writing-plans, TDD, verification, finishing, worktrees). If superpowers skills are not available, stop and tell the user: "forge-brainstorming requires forge-superpowers. Install it first: `claude mcp add-plugin forge-superpowers`." Phases 1-2 (discovery + design) can still provide value standalone if the user explicitly requests it after seeing the warning.

## Phase 1: Discovery

1. Parse arguments: extract feature description, detect `--auto-plan`, `--skip-pr`, and `--comment` flags
2. Create a slug from the feature description (lowercase, hyphens, max 30 chars)
3. Create team: `TeamCreate(team_name: "brainstorming-{slug}")`
4. Create Phase 1 tasks in the task list
5. Spawn scout: `Agent(name: "scout", subagent_type: "forge-brainstorming:scout", team_name: "brainstorming-{slug}")`
6. Send scout the exploration assignment (see `references/phase-orchestration.md` for message template):
   - Include the feature description
   - Request 3 passes: similar features, architecture, integration points
   - Request 5-10 key files per pass
7. When scout reports back: read the key files scout identified to build your own deep understanding
8. Compile clarifying questions from scout's findings + your own analysis

### Gate 1: Clarifying Questions (MANDATORY)

Present to user (see `references/gate-protocols.md`):
- Brief summary of scout's key findings
- Relevant patterns discovered
- Organized clarifying questions grouped by topic (scope, behavior, integration, preferences)
- Risks and constraints discovered
- Early exit option

**WAIT for user answers before proceeding.** If user says "whatever you think", provide recommended answers and get explicit confirmation.

## Phase 2: Design

1. Spawn architect: `Agent(name: "architect", subagent_type: "forge-brainstorming:architect", team_name: "brainstorming-{slug}")`
2. Send architect (see `references/phase-orchestration.md`):
   - Feature description
   - Scout's compiled findings (all 3 passes)
   - User's answers to clarifying questions
   - Constraints from CLAUDE.md and scout's risks
   - Request 2-3 genuinely different approaches
3. When architect reports: review all approaches for completeness

### Gate 2: Architecture Choice (MANDATORY)

Present to user (see `references/gate-protocols.md`):
- Comparison table of all approaches
- Trade-offs for each (pros/cons)
- Your recommendation with reasoning
- Early exit option

**WAIT for user choice.** If user wants refinement, relay feedback to architect, architect refines, re-present.

## Phase 3: Planning

1. Announce: "I'm using the writing-plans skill to create the implementation plan."
2. Use **superpowers:writing-plans** to convert chosen architecture into a detailed TDD plan
   - Include all context from Phases 1-2: scout findings, user requirements, chosen architecture
   - Each task follows TDD: write failing test → verify failure → implement → verify pass → commit
   - Save to `docs/superpowers/plans/YYYY-MM-DD-{feature-name}.md`
3. If reviewer is not yet spawned: spawn reviewer `Agent(name: "reviewer", subagent_type: "forge-brainstorming:reviewer", team_name: "brainstorming-{slug}")`
4. Send reviewer spec validation request: `MODE: spec-validation` with the plan file path
5. Handle reviewer response:
   - If approved: proceed
   - If issues found: address them in the plan, re-validate
6. **Shutdown scout and architect** — they are no longer needed:
   - `SendMessage(to: "scout", message: {type: "shutdown_request"})`
   - `SendMessage(to: "architect", message: {type: "shutdown_request"})`

### Gate 3: Plan Approval (SOFT — skipped with --auto-plan)

If `--auto-plan` flag: auto-approve and proceed to Phase 4.

Otherwise, present to user (see `references/gate-protocols.md`):
- Plan summary: number of tasks, components, technologies
- Task list overview (titles)
- Reviewer's spec validation result
- Early exit option (user can take plan and run `/subagent-driven-development` themselves)

**WAIT for approval.**

## Phase 4: Execution

1. Set up isolated workspace: use **superpowers:using-git-worktrees**
2. Spawn builder: `Agent(name: "builder", subagent_type: "forge-brainstorming:builder", team_name: "brainstorming-{slug}")`
3. Ensure reviewer is active (spawned in Phase 3)

### Per-Task Loop

For each task in the plan, repeat:

**A. Dispatch to builder:**
- Send full task text via SendMessage (NEVER make builder read plan file)
- Include architectural context, dependencies on previous tasks, working directory
- Request TDD protocol and status report

**B. Handle builder response:**
- **DONE** → proceed to reviewer
- **DONE_WITH_CONCERNS** → read concerns, decide whether to address first
- **NEEDS_CONTEXT** → provide missing context, re-dispatch
- **BLOCKED** → assess: provide context, break task, or escalate to user

**C. Dispatch to reviewer (per-task mode):**
- Send `MODE: per-task` with task spec, builder's report, and git range
- Reviewer runs Stage 1 (spec compliance) then Stage 2 (code quality)

**D. Handle reviewer response:**
- If passes both stages → mark task complete, proceed to next task
- If issues found → send issues to builder, builder fixes, re-send to reviewer (LOOP)

**After ALL tasks complete:** proceed to Phase 5.

## Phase 5: Deep Review

1. Send reviewer deep review request: `MODE: deep-review`
   - Include branch info, list of changed files
   - Request all 5 lenses (or applicable subset)
   - Reviewer can dispatch lenses as parallel sub-agents
2. When reviewer reports aggregated results:
   - **Shutdown builder** — no longer needed: `SendMessage(to: "builder", message: {type: "shutdown_request"})`

### Gate 4: Review Findings (CONDITIONAL)

**If critical or important issues found:**
- Present deep review summary to user
- Options: fix now (recommended), fix critical only, proceed as-is
- If fixing: re-spawn builder with `Agent(name: "builder", subagent_type: "forge-brainstorming:builder", team_name: "brainstorming-{slug}")`. Send the re-spawned builder: (1) feature description, (2) chosen architecture summary, (3) list of changed files, (4) specific issues to fix with file:line references. Acknowledge the re-spawned builder lacks prior context. After fixes, re-run affected review lenses only

**If only suggestions or no issues:**
- Auto-proceed, mention suggestions to user
- Offer to address suggestions if user wants

## Phase 6: PR & Close

If `--skip-pr` flag: skip this phase, present session summary, shutdown, done.

1. Spawn closer: `Agent(name: "closer", subagent_type: "forge-brainstorming:closer", team_name: "brainstorming-{slug}")`
2. Send closer the closing assignment (see `references/phase-orchestration.md`):
   - Feature description, branch info, flags
   - Architecture summary for PR body
   - Request: verify → present options → execute → review
3. Handle closer's responses:
   - Relay finishing options to user, relay choice back to closer
   - Share PR URL with user when created
   - Share review findings when complete

### Cleanup

After Phase 6 (or early exit at any gate):
1. **Shutdown all active teammates**: send `{type: "shutdown_request"}` to each active teammate by name
2. **Delete team**: `TeamDelete()`
3. Present final session summary:
   - What was built
   - Key decisions made
   - Artifacts created (spec, plan, PR)
   - Files modified
   - Review findings summary
   - Suggested next steps

## Failure Handling

### Teammate Non-Response
If a teammate does not respond after a reasonable number of follow-up messages (2 attempts), or responds with empty/malformed output that doesn't match expected format:
1. Surface the situation to the user: "[teammate] is not responding or produced unexpected output"
2. Offer options: retry, skip this teammate's phase, or abort
3. Never silently proceed with incomplete data from a failed teammate

### Retry Limits
- **Builder BLOCKED/NEEDS_CONTEXT**: If the same task reports BLOCKED or NEEDS_CONTEXT more than 2 times after receiving additional context, escalate to the user with: what the task requires, what was tried, what specifically is blocking
- **Reviewer fix loop**: If a task fails review 3 times (builder fixes, reviewer still finds issues), pause and present to user: the task spec, builder's latest implementation, and reviewer's unresolved findings. Let user decide: adjust spec, accept as-is, or provide guidance
- **Scout/architect stuck**: If scout or architect cannot complete their work, they should report their partial findings and what specifically blocked them. Present to user immediately

### Closer Verification Failure
If closer reports verification FAIL:
1. Present failure details to user (which tests fail, uncommitted changes, branch divergence)
2. If tests fail: offer to re-spawn builder for targeted fixes, then re-verify
3. If uncommitted changes: instruct closer to commit them
4. If branch diverged: offer rebase with user confirmation
5. Do NOT proceed to PR creation until verification passes

### Deep Review Incomplete
If any review lens sub-agent fails during Phase 5, the reviewer must:
1. Note the missing lens explicitly in the summary
2. Attempt the failed lens sequentially (not as sub-agent)
3. If still fails: report "Deep review incomplete — Lens N could not be applied" with reason
4. Never present a partial review as complete

## Key Rules

- **Never skip mandatory gates** (Gate 1 and Gate 2) — user input is essential for good outcomes
- **Never make teammates read the plan file** — always send full task text via SendMessage
- **Never proceed to code quality review until spec compliance passes**
- **Never create PR if tests fail** — verification must pass first
- **Always offer early exit** at every gate
- **Shutdown teammates when their phases end** — don't waste context on idle agents
- **Never silently proceed with incomplete data** — surface failures to user
