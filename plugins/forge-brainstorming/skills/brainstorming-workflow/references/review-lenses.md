# Review Lenses — Deep Review Protocols

5 specialized review protocols for the reviewer teammate's deep review mode (Phase 5). Each lens focuses on one quality dimension. The reviewer can dispatch these as parallel sub-agents or apply them sequentially.

These protocols are adapted from forge-deep-review's specialized agents (pr-test-analyzer, silent-failure-hunter, type-design-analyzer, comment-analyzer, code-simplifier) for use as reviewer instructions rather than standalone agent definitions.

---

## Lens 1: Test Coverage

**Focus:** Behavioral coverage quality, not line count.

**Process:**
1. Examine all changed files to understand new functionality
2. Review accompanying tests to map coverage to functionality
3. Identify critical paths that could cause production issues if broken
4. Check for tests too tightly coupled to implementation
5. Look for missing negative cases and error scenarios
6. Consider integration points and their test coverage

**What to check:**
- Untested error handling paths that could cause silent failures
- Missing edge case coverage for boundary conditions
- Uncovered critical business logic branches
- Absent negative test cases for validation logic
- Missing tests for concurrent or async behavior where relevant
- Tests that verify behavior and contracts rather than implementation details

**Rating each finding (1-10):**
- 9-10: Critical — data loss, security issues, system failures
- 7-8: Important — user-facing errors
- 5-6: Edge cases — confusion or minor issues
- 3-4: Nice-to-have completeness
- 1-2: Optional improvements

**Output:** Summary, Critical Gaps (8-10), Important Improvements (5-7), Test Quality Issues, Positive Observations

---

## Lens 2: Silent Failures

**Focus:** Zero tolerance for errors that go unnoticed.

**Process:**
1. Locate ALL error handling code:
   - try-catch blocks, error callbacks, error event handlers
   - Conditional branches handling error states
   - Fallback logic and default values on failure
   - Optional chaining that might hide errors
2. Scrutinize each handler for:
   - **Logging quality**: appropriate severity? sufficient context? debuggable in 6 months?
   - **User feedback**: clear, actionable error message?
   - **Catch specificity**: catches only expected types? could suppress unrelated errors?
   - **Fallback behavior**: explicitly justified? masks the real problem?
   - **Error propagation**: should this bubble up instead of being caught here?
3. Check for hidden failure patterns:
   - Empty catch blocks (absolutely forbidden)
   - Catch-log-continue without user awareness
   - Returning null/default on error without logging
   - Silent optional chaining over operations that shouldn't fail silently
   - Retry logic that exhausts without informing anyone

**Severity levels:**
- CRITICAL: Silent failure, broad catch hiding errors
- HIGH: Poor error message, unjustified fallback
- MEDIUM: Missing context, could be more specific

**Output per issue:** Location (file:line), Severity, Issue Description, Hidden Errors (what could be caught), User Impact, Recommendation, Example corrected code

---

## Lens 3: Type Design

**Focus:** Invariant strength, encapsulation quality, enforcement.

**Analysis per type:**
1. **Identify Invariants**: data consistency, valid state transitions, relationship constraints, business logic rules, pre/post conditions
2. **Evaluate Encapsulation** (1-10): internals hidden? invariants violable from outside? minimal complete interface?
3. **Assess Invariant Expression** (1-10): clearly communicated? compile-time enforcement? self-documenting?
4. **Judge Invariant Usefulness** (1-10): prevents real bugs? aligned with requirements? appropriate strictness?
5. **Examine Enforcement** (1-10): checked at construction? all mutation guarded? impossible to create invalid instances?

**Anti-patterns to flag:**
- Anemic domain models with no behavior
- Types exposing mutable internals
- Invariants enforced only through documentation
- Types with too many responsibilities
- Missing validation at construction boundaries

**Principles:**
- Prefer compile-time guarantees over runtime checks
- Value clarity over cleverness
- Make illegal states unrepresentable
- Constructor validation is crucial
- Immutability simplifies invariant maintenance

**Output per type:** Type name, Invariants identified, Ratings (4 dimensions), Strengths, Concerns, Recommended improvements

---

## Lens 4: Comment Accuracy

**Focus:** Protect from comment rot — every comment must add genuine value and remain accurate.

**Process:**
1. **Verify Factual Accuracy**: Cross-reference against code:
   - Function signatures match documented parameters/return types?
   - Described behavior aligns with actual logic?
   - Referenced entities exist and are used correctly?
   - Edge cases mentioned are actually handled?
   - Performance/complexity claims are accurate?
2. **Assess Completeness**:
   - Critical assumptions documented?
   - Non-obvious side effects mentioned?
   - Important error conditions described?
   - Complex algorithm approach explained?
   - Business logic rationale captured?
3. **Evaluate Long-term Value**:
   - Comments restating obvious code → flag for removal
   - Comments explaining "why" → high value
   - Comments that will break with likely changes → reconsider
   - Written for least experienced future maintainer?
4. **Identify Misleading Elements**:
   - Ambiguous language with multiple meanings
   - Outdated references to refactored code
   - Assumptions that may no longer hold
   - TODOs or FIXMEs already addressed

**Output:** Summary, Critical Issues (factually incorrect/misleading) with file:line, Improvement Opportunities, Recommended Removals, Positive Findings

---

## Lens 5: Code Simplification

**Focus:** Clarity, consistency, maintainability — preserve exact functionality.

**Process:**
1. Identify recently modified code sections
2. Analyze for opportunities to improve:
   - Reduce unnecessary complexity and nesting
   - Eliminate redundant code and abstractions
   - Improve readability through clear naming
   - Consolidate related logic
   - Remove comments describing obvious code
   - Avoid nested ternaries — prefer switch/if-else
   - Prefer clarity over brevity
3. Apply project-specific standards from CLAUDE.md
4. Verify all functionality remains unchanged
5. Check the refinement is genuinely simpler, not just different

**Balance — avoid:**
- Over-simplification reducing clarity
- Overly clever solutions hard to understand
- Combining too many concerns into one function
- Removing helpful abstractions
- Prioritizing "fewer lines" over readability

**Scope:** Only code modified in this feature branch, unless explicitly instructed to review broader.

**Output:** Simplification opportunities with file:line, before/after examples where helpful, priority (high = readability win, low = minor polish)

---

## Aggregation Format

After running all applicable lenses, aggregate into:

```markdown
# Deep Review Summary

## Critical Issues (X found)
- [Lens N — name]: [issue] [file:line]

## Important Issues (X found)
- [Lens N — name]: [issue] [file:line]

## Suggestions (X found)
- [Lens N — name]: [suggestion] [file:line]

## Strengths
- [what's well done across all lenses]

## Recommended Action
1. Fix critical issues first
2. Address important issues
3. Consider suggestions
4. Re-run review after fixes
```

**Skip irrelevant lenses:** If the implementation has no types (pure scripting), skip Lens 3. If there are no comments, skip Lens 4. Note which lenses were skipped and why.
