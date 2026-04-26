---
# Curated from: anthropics/claude-code (plugins/code-review) — Author: Boris Cherny (Anthropic)
# Customized: renamed to pr-review, terminal-only by default,
#   inline comments require github_inline_comment MCP server
description: "Automated PR review — bugs + CLAUDE.md compliance, terminal output"
argument-hint: "[PR-number-or-url] [--comment]"
allowed-tools: ["Bash(gh issue view:*)", "Bash(gh search:*)", "Bash(gh issue list:*)", "Bash(gh pr comment:*)", "Bash(gh pr diff:*)", "Bash(gh pr view:*)", "Bash(gh pr list:*)", "mcp__github_inline_comment__create_inline_comment"]
---

# PR Review — Automated Pull Request Analysis

Automated code review for pull requests using multiple specialized agents with confidence-based scoring. Results are shown in the terminal. Optionally posts inline GitHub comments if `--comment` is passed and the `github_inline_comment` MCP server is configured.

Use this AFTER `/deep-review` when the PR is pushed and ready for final automated validation.

**Arguments:** "$ARGUMENTS"

## Review Steps

**Agent assumptions (applies to all agents and subagents):**
- All tools are functional and will work without error. Do not test tools or make exploratory calls. Make sure this is clear to every subagent that is launched.
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
- The code will fail to compile or parse (syntax errors, type errors, missing imports, unresolved references)
- The code will definitely produce wrong results regardless of inputs (clear logic errors)
- Clear, unambiguous CLAUDE.md violations where you can quote the exact rule being broken

Do NOT flag:
- Code style or quality concerns
- Potential issues that depend on specific inputs or state
- Subjective suggestions or improvements

If you are not certain an issue is real, do not flag it. False positives erode trust and waste reviewer time.

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

If `--comment` argument was NOT provided, stop here. This is the default mode.

If `--comment` argument IS provided and NO issues were found, post a summary comment using `gh pr comment` and stop.

If `--comment` argument IS provided and issues were found, continue to step 8.

### 8. Create Comment List

Create a list of all comments that you plan on leaving. This is only for you to make sure you are comfortable with the comments. Do not post this list anywhere.

### 9. Post Inline Comments (requires MCP server)

> **Prerequisite:** The `github_inline_comment` MCP server must be configured.
> If it is not available, fall back to posting all issues as a single `gh pr comment` with a formatted list instead.

Post inline comments using `mcp__github_inline_comment__create_inline_comment` with `confirmed: true`. For each comment:
- Provide a brief description of the issue
- For small, self-contained fixes: include a committable suggestion block
- For larger fixes (6+ lines, structural, multi-location): describe the fix without a suggestion block
- Never post a committable suggestion UNLESS committing it fixes the issue entirely. If follow up steps are required, do not leave a committable suggestion.

**Only ONE comment per unique issue. No duplicates.**

**Fallback (no MCP server):** Post a single PR comment via `gh pr comment` with all issues formatted as a list, including file paths and line numbers.

## False Positive Exclusion List

Do NOT flag these in steps 4 and 5:
- Pre-existing issues
- Something that appears to be a bug but is actually correct
- Pedantic nitpicks that a senior engineer would not flag
- Issues that a linter will catch (do not run the linter to verify)
- General code quality concerns (e.g., lack of test coverage, general security issues) unless explicitly required in CLAUDE.md
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

## Integration

`/pr-review` is the post-push automated review. Companion commands:

- `superpowers:requesting-code-review` — intermediate code review during implementation
- `/deep-review all` (this plugin, pre-push) — specialized quality review (tests, errors, types, comments, simplification)
- `/pr-review <PR> --comment` (this plugin, post-push) — automated PR review with inline GitHub comments

**Local vs PR:**
- `/deep-review` is pre-push, runs locally, covers 5 quality dimensions
- `/pr-review` is post-push, posts to GitHub, focuses on bugs + CLAUDE.md compliance

## MCP Server (optional)

Inline GitHub comments require the `github_inline_comment` MCP server. Without it:
- Terminal output works fully (steps 1-7)
- `--comment` falls back to a single `gh pr comment` with all findings

## Notes

- Use `gh` CLI to interact with GitHub. Do not use web fetch.
- Create a todo list before starting.
- Cite and link each issue in comments (include link to CLAUDE.md if referencing a rule)
- When linking to code, use full SHA format: `https://github.com/owner/repo/blob/<full-sha>/path#L<start>-L<end>`
- Provide at least 1 line of context before and after in code links
- If no issues are found and `--comment` argument is provided, post a comment with the following format:

---

## Code review

No issues found. Checked for bugs and CLAUDE.md compliance.

---
