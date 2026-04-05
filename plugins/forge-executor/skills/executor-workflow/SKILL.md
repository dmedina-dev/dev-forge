---
name: executor-workflow
description: |
  Wave-based plan execution methodology for Superpowers plans. Trigger when the user
  mentions "execute plan", "run waves", "wave execution", "plan executor", "multi-wave",
  "checkpoint execution", or when a writing-plans output contains Wave sections that
  need orchestrated execution. Also trigger when discussing plan validation, wave
  branching strategy, or execution checkpoints.
---

# Executor Workflow — Wave-Based Plan Execution

## Overview

The executor workflow extends Superpowers' `brainstorming → writing-plans → executing-plans` flow by structuring plans into **waves**: atomic units of related work with validation, checkpoints, and rollback boundaries.

## When to use

- Plans with 3+ logically distinct layers (data model, API, UI, etc.)
- Features where partial delivery is valuable (each wave produces working code)
- Projects where rollback granularity matters (revert one layer without losing others)
- Complex implementations where inter-layer validation catches issues early

## Flow summary

```
writing-plans (superpowers)
    ↓ produces wave-structured plan
/execute-plan <path>
    ↓
Phase 0: Hybrid Validation
  Level 1: Global (flow-coherence-validator + plan-antagonist)
  Level 2: Per-wave (plan-auditor + plan-antagonist)
    ↓
Phase 1: Sequential Wave Execution
  Per wave: validate → baseline → branch → TDD tasks → review → merge → checkpoint
    ↓
Completion: tests + final review + PR offer
```

## Wave plan format

Plans must follow the format in `references/wave-plan-format.md`. Key elements:
- Metadata block (Goal, Architecture, Tech Stack, Waves count)
- Waves with Objective, Depends-on, Baseline-tests
- Tasks with RED/VERIFY-RED/GREEN/VERIFY-GREEN/COMMIT steps

## Branching strategy

See `references/branching-strategy.md` for full details:
- `flow/<name>` — main flow branch from main
- `plan/<name>-wave-NN` — per-wave branch (persists after merge)
- `checkpoint-wave-NN` — annotated tags at wave boundaries

## Decision autonomy

The orchestrator decides autonomously on minor ambiguities (naming, lint, patterns) and documents in `docs/decisions/`. It ONLY pauses for BLOCKERs, irrecoverable failures, and broken baselines.

## Rollback

Never automatic. On wave failure, the orchestrator presents options and waits for user decision. See `references/branching-strategy.md` for rollback commands.
