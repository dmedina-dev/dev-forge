---
# Curated from: anthropics/claude-code (plugins/pr-review-toolkit) — Author: Daisy Hollman (Anthropic)
# Customized: removed code-reviewer (superpowers handles intermediate reviews), renamed to deep-review
description: "Specialized deep review using 5 expert agents — tests, errors, types, comments, simplification"
argument-hint: "[review-aspects: tests errors types comments simplify all]"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Task"]
---

# Deep Review — Specialized Post-Implementation Analysis

Run specialized review agents that go deeper than general code review. Each agent focuses on one aspect of code quality. Use this AFTER superpowers' intermediate code reviews, for final validation before merge.

**Review Aspects (optional):** "$ARGUMENTS"

## Review Workflow

### 1. Determine Review Scope
- Check git status to identify changed files
- Parse arguments for specific review aspects
- Default: Run all applicable reviews

### 2. Available Review Aspects

| Aspect | Agent | What it checks |
|--------|-------|---------------|
| **tests** | pr-test-analyzer | Test coverage quality, critical gaps, test brittleness |
| **errors** | silent-failure-hunter | Silent failures, empty catches, inadequate error messages |
| **types** | type-design-analyzer | Type invariants, encapsulation, design quality |
| **comments** | comment-analyzer | Comment accuracy, rot, misleading docs |
| **simplify** | code-simplifier | Unnecessary complexity, readability improvements |
| **all** | All 5 agents | Full specialized review |

### 3. Identify Changed Files

```bash
git diff --name-only        # unstaged changes
git diff --cached --name-only  # staged changes
git diff main...HEAD --name-only  # all branch changes
```

### 4. Determine Applicable Reviews

Based on changes:
- **If test files changed**: pr-test-analyzer
- **If error handling changed** (try/catch, error callbacks): silent-failure-hunter
- **If types added/modified**: type-design-analyzer
- **If comments/docs added**: comment-analyzer
- **After passing all reviews**: code-simplifier (polish and refine)

### 5. Launch Review Agents

**Sequential approach** (default):
- Each report is complete before next
- Easier to understand and act on
- Good for interactive review

**Parallel approach** (add `parallel` to arguments):
- Launch all agents simultaneously
- Faster for comprehensive review
- Results come back together

### 6. Aggregate Results

After agents complete, summarize:

```markdown
# Deep Review Summary

## Critical Issues (X found)
- [agent-name]: Issue description [file:line]

## Important Issues (X found)
- [agent-name]: Issue description [file:line]

## Suggestions (X found)
- [agent-name]: Suggestion [file:line]

## Strengths
- What's well-done

## Recommended Action
1. Fix critical issues first
2. Address important issues
3. Consider suggestions
4. Re-run review after fixes
```

## Usage Examples

```bash
# Full specialized review
/deep-review all

# Only test coverage and error handling
/deep-review tests errors

# Only type design analysis
/deep-review types

# Simplify after passing review
/deep-review simplify

# All agents in parallel (faster)
/deep-review all parallel
```

## Integration

`/deep-review` runs pre-push, locally, covering 5 quality dimensions. Companion commands:

- `superpowers:requesting-code-review` — intermediate code review during implementation
- `/deep-review all` (this command, pre-push) — specialized quality review across 5 dimensions
- `/pr-review <PR> --comment` (this plugin, post-push) — automated PR review with inline GitHub comments

The general code-reviewer from superpowers handles intermediate reviews during implementation.
`/deep-review` adds specialized depth that general review can't provide:
- **pr-test-analyzer** finds behavioral test gaps the code-reviewer misses
- **silent-failure-hunter** traces error propagation paths exhaustively
- **type-design-analyzer** evaluates invariant design that code-reviewer doesn't check
- **comment-analyzer** catches comment rot and misleading documentation
- **code-simplifier** polishes code after all functional reviews pass

## Tips

- **Run after superpowers review**: This supplements, not replaces, intermediate reviews
- **Focus on changes**: Agents analyze git diff by default
- **Address critical first**: Fix high-priority issues before lower priority
- **Re-run after fixes**: Verify issues are resolved
- **Use specific reviews**: Target specific aspects when you know the concern
