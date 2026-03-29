---
# Curated from: anthropics/claude-code (plugins/code-review) — Author: Boris Cherny (Anthropic)
# Customized: renamed to pr-review, integrated as Phase D of extended-dev workflow,
#   removed hardcoded anthropics/claude-code link format, generalized repo references
description: "Automated PR review — bugs + CLAUDE.md compliance with inline GitHub comments"
argument-hint: "[PR-number-or-url] [--comment]"
allowed-tools: ["Bash(gh issue view:*)", "Bash(gh search:*)", "Bash(gh issue list:*)", "Bash(gh pr comment:*)", "Bash(gh pr diff:*)", "Bash(gh pr view:*)", "Bash(gh pr list:*)", "mcp__github_inline_comment__create_inline_comment"]
---

# PR Review — Automated Pull Request Analysis

Automated code review for pull requests using multiple specialized agents with confidence-based scoring. Posts inline GitHub comments with actionable findings.

Use this AFTER `/deep-review` (Phase C) when the PR is pushed and ready for final automated validation.

**Arguments:** "$ARGUMENTS"

## Review Steps

**Agent assumptions (applies to all agents and subagents):**
- All tools are functional and will work without error. Do not test tools or make exploratory calls.
- Only call a tool if it is required to complete the task. Every tool call should have a clear purpose.

### 1. Gate Check (haiku agent)

Check if any of the following are true:
- The pull request is closed
- The pull request is a draft
- The pull request does not need code review (e.g. automated PR, trivial change that is obviously correct)
- Claude has already commented on this PR (check `gh pr view <PR> --comments` for comments left by claude)

If any condition is true, stop and do not proceed.

Note: Still review Claude-generated PRs.

### 2. Discover CLAUDE.md Files (haiku agent)

Return a list of file paths (not contents) for all relevant CLAUDE.md files:
- The root CLAUDE.md file, if it exists
- Any CLAUDE.md files in directories containing files modified by the pull request

### 3. PR Summary (sonnet agent)

View the pull request and return a summary of the changes.

### 4. Parallel Review (4 agents)

Launch 4 agents in parallel. Each returns a list of issues with description and reason.

**Agents 1+2**: CLAUDE.md compliance (sonnet) — audit changes for CLAUDE.md compliance in parallel. Only consider CLAUDE.md files that share a path with the file or its parents.

**Agent 3**: Bug scan on diff only (opus) — flag only significant bugs. Do not flag issues that require context outside the git diff to validate.

**Agent 4**: Security/logic in introduced code (opus) — look for problems in the changed code only.

**CRITICAL: HIGH SIGNAL only.** Flag issues where:
- The code will fail to compile or parse (syntax errors, type errors, missing imports)
- The code will definitely produce wrong results regardless of inputs (clear logic errors)
- Clear, unambiguous CLAUDE.md violations where you can quote the exact rule being broken

Do NOT flag:
- Code style or quality concerns
- Potential issues that depend on specific inputs or state
- Subjective suggestions or improvements

If you are not certain an issue is real, do not flag it.

Each subagent should receive the PR title and description for context.

### 5. Validation Pass (parallel agents)

For each issue from agents 3 and 4, launch a parallel subagent to validate:
- Opus agents for bugs and logic issues
- Sonnet agents for CLAUDE.md violations

The agent validates that the stated issue is truly an issue with high confidence.

### 6. Filter

Remove any issues not validated in step 5. This gives us the final list of high-signal issues.

### 7. Output Summary

Output a summary of review findings to the terminal:
- If issues found: list each with a brief description
- If no issues found: "No issues found. Checked for bugs and CLAUDE.md compliance."

If `--comment` argument was NOT provided, stop here.

If `--comment` argument IS provided and NO issues found, post a summary comment using `gh pr comment` and stop.

If `--comment` argument IS provided and issues found, continue to step 8.

### 8. Plan Comments

Create an internal list of all comments you plan to leave. Do not post this list anywhere.

### 9. Post Inline Comments

Post inline comments using `mcp__github_inline_comment__create_inline_comment` with `confirmed: true`. For each comment:
- Provide a brief description of the issue
- For small, self-contained fixes: include a committable suggestion block
- For larger fixes (6+ lines, structural, multi-location): describe the fix without a suggestion block
- Never post a committable suggestion UNLESS committing it fixes the issue entirely

**Only ONE comment per unique issue. No duplicates.**

## False Positive Exclusion List

Do NOT flag these in steps 4 and 5:
- Pre-existing issues
- Something that appears to be a bug but is actually correct
- Pedantic nitpicks that a senior engineer would not flag
- Issues that a linter will catch (do not run the linter to verify)
- General code quality concerns (e.g., lack of test coverage) unless explicitly required in CLAUDE.md
- Issues mentioned in CLAUDE.md but explicitly silenced in code (e.g., lint ignore comment)

## Usage Examples

```bash
# Review PR, output to terminal only
/pr-review 42

# Review PR and post inline GitHub comments
/pr-review 42 --comment

# Review by URL
/pr-review https://github.com/owner/repo/pull/42 --comment
```

## Integration with Extended Dev Workflow

This command is **Phase D** of the extended development workflow:

1. **Phase A**: `/feature-dev` — Discovery, exploration, architecture design
2. **Phase B**: superpowers — TDD planning and execution with intermediate code reviews
3. **Phase C**: `/deep-review all` — Specialized quality review (tests, errors, types, comments, simplification)
4. **Phase D**: `/pr-review <PR> --comment` — Automated PR review with inline GitHub comments

**Phase C vs Phase D:**
- `/deep-review` is pre-push, runs locally, covers 5 quality dimensions
- `/pr-review` is post-push, posts to GitHub, focuses on bugs + CLAUDE.md compliance

## Notes

- Use `gh` CLI to interact with GitHub. Do not use web fetch.
- Cite and link each issue in inline comments (include link to CLAUDE.md if referencing a rule)
- When linking to code, use full SHA format: `https://github.com/owner/repo/blob/<full-sha>/path#L<start>-L<end>`
- Provide at least 1 line of context before and after in code links
