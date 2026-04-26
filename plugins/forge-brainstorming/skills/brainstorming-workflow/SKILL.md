---
name: brainstorming-workflow
description: >
  Full-lifecycle teammate orchestration for complex features. Use when the user invokes
  /brainstorming or asks for "end-to-end development", "full lifecycle", "discovery to PR",
  "teammate-driven development", or "brainstorming with agents". Covers discovery, design,
  planning, TDD execution, deep review, and PR creation with persistent named teammates.
  DO NOT use for simple tasks, single-file changes, bug fixes, or straightforward features
  where the implementation path is clear.
---

# Brainstorming Workflow — Teammate-Driven Development Lifecycle

Orchestrate the full development lifecycle for complex features using 5 persistent teammates, each with a distinct role. One `/brainstorming` command covers discovery through PR.

## Why Teammates Over Subagents

- **Persistent context** — teammates accumulate understanding across phases, no context lost
- **Named coordination** — address teammates by name via SendMessage, clear responsibility
- **Shared task list** — all teammates see progress, dependencies, blockers
- **Single entry point** — one command replaces 4 manual invocations

## Teammate Roster

| Name | Role | Model | Phases |
|------|------|-------|--------|
| **scout** | Codebase Explorer | sonnet | 1-Discovery |
| **architect** | System Designer | opus | 2-Design |
| **builder** | Implementation Lead | inherit | 4-Execution |
| **reviewer** | Quality Gatekeeper (3 modes) | inherit | 3-Planning, 4-Execution, 5-Review |
| **closer** | PR & Integration | inherit | 6-PR |

## 6-Phase Flow

```
Phase 1: Discovery    → scout explores codebase (3 passes)
  ║ GATE 1: Clarifying Questions (mandatory)
Phase 2: Design       → architect designs 2-3 approaches
  ║ GATE 2: Architecture Choice (mandatory)
Phase 3: Planning     → orchestrator writes TDD plan, reviewer validates spec
  ║ GATE 3: Plan Approval (soft, --auto-plan skips)
Phase 4: Execution    → builder implements via TDD, reviewer checks each task
Phase 5: Deep Review  → reviewer applies 5 lenses (tests, errors, types, comments, simplify)
  ║ GATE 4: Fix/Proceed (conditional — only if critical/important found)
Phase 6: PR & Close   → closer verifies, creates PR, runs automated review
```

## Progressive Engagement

Stop at any gate:
- After Phase 1: "I just needed the exploration"
- After Phase 2: "I have the architecture, I'll implement myself"
- After Phase 3: "I have the plan, I'll use `/subagent-driven-development`"
- After Phase 5: "Skip PR, I'll handle that"

## Gates

See `references/gate-protocols.md` for detailed interaction patterns:
- **Gate 1** (mandatory): present scout findings + clarifying questions, wait for answers
- **Gate 2** (mandatory): present architect's approaches + recommendation, wait for choice
- **Gate 3** (soft): present plan summary, approve to proceed (--auto-plan skips)
- **Gate 4** (conditional): only pauses if critical/important issues found

## Deep Review Lenses

See `references/review-lenses.md` for the 5 specialized protocols:
1. Test Coverage — behavioral coverage, critical gaps
2. Silent Failures — empty catches, swallowed errors
3. Type Design — invariant strength, encapsulation
4. Comment Accuracy — factual accuracy, rot
5. Code Simplification — clarity, maintainability

## Phase Orchestration

See `references/phase-orchestration.md` for:
- Message templates for each teammate per phase
- Task creation templates
- Transition criteria between phases
- Teammate lifecycle management (spawn/shutdown timing)

## Integration

**Requires:** forge-superpowers (provides writing-plans, TDD, verification, finishing, worktrees)

**Superpowers skills used:**
- `superpowers:writing-plans` — Phase 3 plan generation
- `superpowers:using-git-worktrees` — Phase 4 workspace isolation
- `superpowers:test-driven-development` — builder follows TDD protocol
- `superpowers:verification-before-completion` — Phase 6 pre-PR verification
- `superpowers:finishing-a-development-branch` — Phase 6 integration options

**Complements:** `superpowers:brainstorming` — user chooses between `/brainstorming` (persistent teammates that accumulate context across phases) or superpowers' inline brainstorming (single-turn ideation, no persistent state)

## Command

```bash
/brainstorming [feature description] [--auto-plan] [--skip-pr] [--comment]
```

- `--auto-plan`: skip Gate 3 (auto-approve plan)
- `--skip-pr`: stop after deep review, skip PR phase
- `--comment`: post inline GitHub comments during PR review (requires `gh` CLI)
