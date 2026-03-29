---
name: session-keeper
description: >
  Keeps CLAUDE.md, project documentation and memories in sync after development
  sessions. This skill should activate when detecting semantic context shifts:
  the conversation moves between different domain areas (e.g., from auth to
  payments), shifts from frontend to backend or across monorepo zones, makes
  significant architectural decisions, or accumulates substantial changes that
  haven't been captured in project context. Also activates with explicit
  /session-keeper:sync. Use when the user mentions "update context", "sync docs",
  "refresh CLAUDE.md", "session handoff", "save progress", or when you detect
  the conversation has drifted across multiple concerns without a sync.
---

# Session Keeper

Keeps project context synchronized across Claude Code sessions.

## When to run

- When you detect the conversation shifting between different domains or zones
- When the human explicitly requests it
- After the context-aware hook reminder (safety net)
- At the end of long sessions or before `/compact`
- After significant architectural decisions

## Synchronization process

### Step 1: Analyze session changes

Run `git diff --name-only HEAD~5` (or appropriate range based on session length)
to identify changed files. Also check `git diff --name-only` for uncommitted work.
Classify by top-level directory (monorepo zone).

### Step 2: Update CLAUDE.md per zone

For each zone with significant changes, read the existing CLAUDE.md and
identify new information this session contributes:
- New conventions discovered or established
- Build/test commands that changed
- Architectural decisions made
- Gotchas or bugs found and resolved
- Dependencies added or removed

Constraints:
- Maximum ~200 lines root, ~100 lines children
- Don't duplicate linter/formatter rules
- Don't describe individual files
- Specific, verifiable instructions only
- Prune oldest/most obvious if over limit

Refer to `references/claudemd-guide.md` for detailed rules.

### Step 3: Update .claude/rules/ if needed

If new cross-cutting conventions emerged (testing patterns, security rules,
style decisions), propose additions to `.claude/rules/` with path frontmatter.

### Step 4: Update project documentation

Check if session changes affect:
- `docs/` → existing technical documentation
- `README.md` → if setup or commands changed
- `docs/adr/` → if significant architectural decisions were made

### Step 5: Generate session summary

Save to `docs/sessions/YYYY-MM-DD-title.md`:

```
## Session: [date] — [descriptive title]

### Changes made
- [List of main changes]

### Decisions taken
- [Decision]: [short rationale]

### Current status
- Completed: [what was finished]
- In progress: [what's half-done]
- Pending: [what was identified but not started]

### Context for next session
- [What the next Claude needs to know]
```

### Step 6: Present to the human

Show diff of all proposed changes. **DO NOT apply without confirmation.**
After applying, run `${CLAUDE_PLUGIN_ROOT}/scripts/reset-watch.sh` to reset
the watcher.

## Reference files

For CLAUDE.md maintenance rules → `references/claudemd-guide.md`
For monorepo patterns → `references/monorepo-patterns.md`
