---
name: extended-dev-workflow
description: >
  Reference for the extended development workflow that combines feature-dev discovery,
  superpowers TDD execution, specialized deep review, and automated PR review.
  Consult when planning how phases connect or when deciding which tool to use at each stage.
---

# Extended Development Workflow

Combines four sources into one unified flow:
- **feature-dev** (Anthropic) → Discovery, exploration, architecture design
- **superpowers** (obra) → TDD planning, execution, verification, debugging
- **pr-review-toolkit** (Anthropic) → Specialized post-implementation review
- **code-review** (Anthropic) → Automated PR review with inline GitHub comments

## The Full Flow

```
┌─────────────────────────────────────────────────┐
│  PHASE A: DISCOVERY & DESIGN                    │
│  Command: /feature-dev [description]             │
│                                                  │
│  1. Discovery — understand what to build         │
│  2. Codebase Exploration — code-explorer agents  │
│  3. Clarifying Questions — gate: wait for user   │
│  4. Architecture Design — code-architect agents  │
│     gate: wait for user choice                   │
│                                                  │
├─────────────────────────────────────────────────┤
│  PHASE B: TDD EXECUTION (superpowers)           │
│                                                  │
│  5. writing-plans → TDD plan from architecture   │
│  6. subagent-driven-dev or executing-plans       │
│     - Each task: test → implement → verify       │
│     - Two-stage review: spec + quality           │
│  7. verification-before-completion               │
│  8. finishing-a-development-branch               │
│                                                  │
├─────────────────────────────────────────────────┤
│  PHASE C: SPECIALIZED REVIEW                    │
│  Command: /deep-review [aspects]                 │
│                                                  │
│  9. Run specialized agents by aspect:            │
│     - tests — test coverage gaps                 │
│     - errors — silent failures                   │
│     - types — type design quality                │
│     - comments — comment accuracy                │
│     - simplify — code simplification             │
│     - all — run everything                       │
│                                                  │
├─────────────────────────────────────────────────┤
│  PHASE D: PR REVIEW                             │
│  Command: /pr-review [PR] [--comment]            │
│                                                  │
│  10. Gate check — skip draft/closed/trivial PRs  │
│  11. CLAUDE.md discovery — find relevant rules   │
│  12. 4 parallel agents: CLAUDE.md compliance x2  │
│      + bug scan + security/logic scan            │
│  13. Validation pass — verify each finding       │
│  14. Post inline GitHub comments (if --comment)  │
│                                                  │
└─────────────────────────────────────────────────┘
```

## When to Use Each Phase

**Phase A only** — When exploring a new codebase or designing a feature you'll implement later.

**Phase B only** — When you already have a clear spec/plan and just need TDD execution (superpowers standalone).

**Phase C only** — When reviewing existing code or a PR after implementation (`/deep-review tests errors`).

**Phase D only** — When a PR is already pushed and you want automated GitHub review (`/pr-review 42 --comment`).

**Full flow (A → B → C → D)** — For new features that need exploration, design, implementation, deep review, and automated PR validation.

## Key Handoff Points

### A → B: Architecture to Plan
The `/feature-dev` command produces an approved architecture. Phase B converts it into a TDD plan via `superpowers:writing-plans`. The plan inherits all context: codebase patterns, clarified requirements, chosen architecture approach.

### B → C: Implementation to Review
After `superpowers:finishing-a-development-branch`, run `/deep-review all` for specialized review. This catches issues the intermediate code reviews might miss: silent failures, type design flaws, test gaps, misleading comments.

### C → D: Local Review to PR Review
After `/deep-review` passes and the PR is pushed, run `/pr-review <PR> --comment` for automated GitHub validation. This is the final quality gate — catches bugs and CLAUDE.md violations with inline comments that other reviewers (or you) can act on.

## Agent Inventory

| Agent | Source | Role | Model |
|-------|--------|------|-------|
| code-explorer | feature-dev | Trace codebase, map architecture | sonnet |
| code-architect | feature-dev | Design implementation blueprints | sonnet |
| comment-analyzer | pr-review-toolkit | Verify comment accuracy | inherit |
| pr-test-analyzer | pr-review-toolkit | Evaluate test coverage | inherit |
| silent-failure-hunter | pr-review-toolkit | Find hidden error handling gaps | inherit |
| type-design-analyzer | pr-review-toolkit | Analyze type invariants | inherit |
| code-simplifier | pr-review-toolkit | Suggest simplifications | inherit |

## Dependencies

**Requires:** forge-superpowers (provides TDD execution, verification, debugging, git worktrees, finishing workflow)

**Superpowers skills used:**
- writing-plans, executing-plans, subagent-driven-development
- test-driven-development, systematic-debugging
- verification-before-completion, finishing-a-development-branch
- requesting-code-review, receiving-code-review
- dispatching-parallel-agents, using-git-worktrees
- brainstorming (optional, for Phase A complex design)
