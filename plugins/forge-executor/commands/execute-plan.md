---
description: "Execute a multi-wave Superpowers plan with hybrid validation, TDD, checkpoints, and manual rollback"
argument-hint: "<path-to-plan.md> [--skip-global-validation] [--resume-from-wave N] [--dry-run]"
---

# Execute Plan — Wave-Based Superpowers Orchestration

You are launching the superpowers-orchestrator to execute a multi-wave plan.

**Plan source:** $ARGUMENTS

## Argument parsing

1. Extract the plan path (first positional argument, required)
2. Detect flags:
   - `--skip-global-validation`: skip Phase 0 Level 1 (use when re-executing after fixes)
   - `--resume-from-wave N`: resume from wave N (assumes checkpoints exist)
   - `--dry-run`: run Phase 0 validation only, do not execute

## Prerequisites check

This command **requires forge-superpowers** plugin (provides writing-plans, TDD, verification, finishing, worktrees). If superpowers skills are not available, stop and tell the user: "forge-executor requires forge-superpowers. Install it first."

## Execution

### If plan path provided:

1. Read the plan file
2. Validate it follows the wave plan format (see `references/wave-plan-format.md`)
3. Dispatch `superpowers-orchestrator` agent with the full plan and flags

### If --resume-from-wave N:

1. Verify flow branch exists: `git branch --list "flow/*"`
2. Verify checkpoint tag exists: `git tag -l "checkpoint-wave-*"`
3. Read the enriched plan from `docs/plans/`
4. Dispatch orchestrator with resume context:
   - Current branch state
   - Completed waves (from tags)
   - Remaining waves from plan
   - Decision log so far

### If --dry-run:

1. Read the plan file
2. Run Phase 0 only (both validation levels for all waves)
3. Report consolidated findings
4. Do NOT create branches, tags, or execute any code

### If no plan path:

Look for recent plan files in `docs/plans/` and offer to execute the most recent one.

## Post-execution

After the orchestrator completes (or pauses for user input), summarize:
- Waves completed / total
- Current checkpoint
- Pending decisions (if any)
- Next action needed
