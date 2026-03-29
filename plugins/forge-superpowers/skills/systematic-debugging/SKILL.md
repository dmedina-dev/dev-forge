---
# Curated from: obra/superpowers v5.0.6
name: systematic-debugging
description: Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes
---

# Systematic Debugging

## Overview

Random fixes waste time and create new bugs. Quick patches mask underlying issues.

**Core principle:** ALWAYS find root cause before attempting fixes. Symptom fixes are failure.

## The Iron Law

```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

If you haven't completed Phase 1, you cannot propose fixes.

## When to Use

Use for ANY technical issue: test failures, bugs, unexpected behavior, performance problems, build failures, integration issues.

**Use ESPECIALLY when:**
- Under time pressure (emergencies make guessing tempting)
- "Just one quick fix" seems obvious
- You've already tried multiple fixes
- You don't fully understand the issue

## The Four Phases

### Phase 1: Root Cause Investigation

**BEFORE attempting ANY fix:**

1. **Read Error Messages Carefully** — Don't skip past errors. Read stack traces completely.
2. **Reproduce Consistently** — Can you trigger it reliably?
3. **Check Recent Changes** — What changed? Git diff, recent commits, config changes.
4. **Gather Evidence in Multi-Component Systems** — Add diagnostic instrumentation at each component boundary. Run once to gather evidence showing WHERE it breaks.
5. **Trace Data Flow** — See `root-cause-tracing.md` for backward tracing technique.

### Phase 2: Pattern Analysis

1. **Find Working Examples** — Locate similar working code in same codebase
2. **Compare Against References** — Read reference implementation COMPLETELY
3. **Identify Differences** — List every difference, however small
4. **Understand Dependencies** — What components, settings, environment?

### Phase 3: Hypothesis and Testing

1. **Form Single Hypothesis** — "I think X is the root cause because Y"
2. **Test Minimally** — Smallest possible change, one variable at a time
3. **Verify Before Continuing** — Worked? → Phase 4. Didn't work? → New hypothesis.
4. **When You Don't Know** — Say so. Ask for help.

### Phase 4: Implementation

1. **Create Failing Test Case** — Use superpowers:test-driven-development
2. **Implement Single Fix** — ONE change at a time
3. **Verify Fix** — Test passes? No regressions?
4. **If Fix Doesn't Work** — If < 3 attempts: return to Phase 1. If >= 3: question architecture.
5. **If 3+ Fixes Failed** — STOP and discuss with human partner. This is an architectural problem.

## Red Flags - STOP and Follow Process

If you catch yourself thinking:
- "Quick fix for now, investigate later"
- "Just try changing X and see if it works"
- "I don't fully understand but this might work"
- Proposing solutions before tracing data flow

**ALL of these mean: STOP. Return to Phase 1.**

## Supporting Techniques

- **`root-cause-tracing.md`** — Trace bugs backward through call stack
- **`defense-in-depth.md`** — Add validation at multiple layers after finding root cause
- **`condition-based-waiting.md`** — Replace arbitrary timeouts with condition polling

## Integration

- **superpowers:test-driven-development** — For creating failing test case (Phase 4)
- **superpowers:verification-before-completion** — Verify fix worked before claiming success
