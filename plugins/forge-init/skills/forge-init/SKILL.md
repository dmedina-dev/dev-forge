---
name: forge-init
description: >
  Two-step project bootstrapper for Claude Code. Step 1 runs the native /init
  to interview the developer and generate base configuration. Step 2 layers
  opinionated conventions on top: CLAUDE.md quality improvements, per-directory
  context files, path-scoped rules, documentation scaffolding. Use this skill
  when bootstrapping a new project, adding Claude Code support to an existing
  project, or when the user mentions "initialize", "bootstrap", "setup project",
  "forge init", or any variant that implies first-time configuration. This
  plugin is designed to be uninstalled after use.
---

# Forge Init

Two-step bootstrapper: native /init foundation + conventions layer.

## Step 1 — Run native /init

Tell the human:

"I'll start by running the native /init with the experimental interview mode.
This will ask you about your project, workflows, and preferences to generate
the base configuration. After that, I'll add our conventions layer on top."

Then guide the human to run:

```
CLAUDE_CODE_NEW_INIT=1 /init
```

Wait for /init to complete. It will generate:
- Root CLAUDE.md (and possibly per-directory ones)
- Skills and hooks based on the interview
- .claude/ configuration

If /init is not available or the experimental flag doesn't work, fall back
to the manual discovery process described in `references/manual-discovery.md`.

## Step 2 — Conventions layer

After /init completes, audit and enhance the result:

### 2.1 Audit CLAUDE.md quality

Read every CLAUDE.md that /init generated. Check against best practices
in `references/claudemd-conventions.md`:

- Is root CLAUDE.md under ~200 lines?
- Does it follow the WHY/WHAT/HOW structure?
- Does it avoid duplicating linter/formatter rules?
- Are instructions specific and verifiable?
- Is there anything Claude already knows that should be removed?

Propose improvements. Present a diff to the human for approval.

### 2.2 Fill per-directory gaps

Scan the project structure and identify directories that deserve their
own CLAUDE.md but didn't get one from /init:

- Each app in apps/ with its own stack
- Domain directories with DDD conventions
- Shared libraries with cross-package impact
- Infrastructure directories with deploy commands

For each gap, generate a CLAUDE.md following the conventions guide.
Keep children under ~100 lines. They supplement the root, not repeat it.

### 2.3 Add path-scoped rules

Check if /init created `.claude/rules/`. If not, or if coverage is
incomplete, propose cross-cutting rules:

- Testing conventions → `paths: **/*.test.ts, **/*.spec.ts`
- Security rules → `paths: domains/**, shared/auth/**`
- Style conventions → as needed

Use `.claude/rules/` with frontmatter path scoping. Only create rules
for conventions that are truly cross-cutting. Directory-specific rules
belong in that directory's CLAUDE.md.

### 2.4 Documentation scaffolding

Create if they don't exist:

```bash
mkdir -p docs/sessions
mkdir -p docs/adr
```

Create `docs/sessions/.gitkeep`.

Create `docs/adr/0001-template.md`:

```markdown
# [NUMBER]. [TITLE]

**Date:** YYYY-MM-DD
**Status:** proposed | accepted | deprecated | superseded

## Context
[What is the issue motivating this decision?]

## Decision
[What change are we proposing/doing?]

## Consequences
[What becomes easier or harder because of this change?]
```

### 2.5 Personal overrides file

Create `CLAUDE.local.md` if it doesn't exist:

```markdown
# Personal overrides
# This file is gitignored — for developer-specific preferences
```

Add `CLAUDE.local.md` to `.gitignore` if not already there.

### 2.6 Generate initialization report

Create `docs/sessions/YYYY-MM-DD-forge-init.md` documenting:
- What /init discovered and generated (step 1)
- What the conventions layer added/improved (step 2)
- Decisions made during initialization
- Recommended next steps

### 2.7 Present and confirm

Show the human a complete summary:
1. Files created or modified
2. Diff of CLAUDE.md improvements
3. Rules added
4. Documentation scaffolding

**DO NOT write any files until the human confirms.**

## Step 3 — Self-cleanup

After initialization is approved and applied:

```
✅ Project initialized with dev-forge conventions.

To uninstall forge-init (no longer needed):
  /plugin → Manage and uninstall plugins → forge-init → Uninstall

session-keeper is active for ongoing maintenance.
Run /session-keeper:status to check context health anytime.
```

## Reference files

For CLAUDE.md conventions → read `references/claudemd-conventions.md`
For manual discovery fallback → read `references/manual-discovery.md`
