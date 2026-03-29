---
description: Shows project context health — CLAUDE.md files, last updates, drift, and .claude/rules/ coverage.
---

Generate a context health report:

1. List all CLAUDE.md files with last modification date
2. List .claude/rules/ files with their path scopes
3. Compare against recently modified files (git log --since="1 week")
4. Identify zones with drift (code changed but context didn't)
5. Show last session summary if one exists

Output format:
```
Context health — [project name]

CLAUDE.md             Last updated       Drift?
─────────────────────────────────────────────────
./CLAUDE.md           2 days ago         [warn] 12 files changed
apps/api/CLAUDE.md    1 week ago         [ok] no changes
apps/web/CLAUDE.md    does not exist     [missing] 43 files without context
shared/CLAUDE.md      3 days ago         [warn] 5 files changed

Rules                 Scope
─────────────────────────────────────────────────
testing.md            **/*.test.ts, **/*.spec.ts
security.md           domains/**, shared/auth/**

Last session: YYYY-MM-DD — "Session title"
```
