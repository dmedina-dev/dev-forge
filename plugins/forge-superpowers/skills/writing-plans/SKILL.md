---
# Curated from: obra/superpowers v5.0.6
name: writing-plans
description: Use when you need to create a detailed implementation plan for a multi-step feature or task
---

# Writing Plans

## Overview

Develop thorough implementation plans for multi-step tasks, assuming the engineer lacks codebase familiarity. Document essential information: files to modify, code samples, testing approaches, documentation to review, and validation methods. Break work into manageable tasks. Follow DRY, YAGNI, and TDD principles. Commit frequently.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Save plans to:** `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`
- User preferences override this default location

## Scope Check

If the spec addresses multiple independent subsystems, recommend creating separate plans — one per subsystem. Each plan should produce independently testable, working software.

## File Structure

Map files to create or modify before defining tasks:
- Design units with clear boundaries and interfaces
- Collocate related files; organize by responsibility, not technical layer
- In existing codebases, follow established patterns

## Bite-Sized Task Granularity

Each step takes 2-5 minutes, representing one action:
- Write failing test
- Verify failure
- Implement minimal solution
- Verify passing test
- Commit changes

## Plan Document Header

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** [One sentence]
**Architecture:** [2-3 sentences]
**Tech Stack:** [Key technologies]

---
```

## Task Structure

````markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

- [ ] **Step 1: Write the failing test**
- [ ] **Step 2: Run test to verify it fails**
- [ ] **Step 3: Write minimal implementation**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit**
````

## No Placeholders

Every step contains complete, actionable content. Never write TBD, TODO, or vague directives.

## Self-Review Checklist

1. **Spec coverage:** Match each requirement to a task. Note gaps.
2. **Placeholder scan:** Search for red flags. Fix inline.
3. **Type consistency:** Verify function names and signatures remain consistent across tasks.

## Execution Handoff

After saving, offer execution options:

**1. Subagent-Driven (recommended)** — Fresh subagent per task, review between tasks
**2. Inline Execution** — Execute tasks in current session using executing-plans

## Integration

- **superpowers:brainstorming** — Creates the design this skill turns into a plan
- **superpowers:subagent-driven-development** — Executes the plan with subagents
- **superpowers:executing-plans** — Executes the plan inline
