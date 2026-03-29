# Dev Forge Marketplace Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Claude Code plugin marketplace with two plugins — forge-init (disposable bootstrapper) and forge-keeper (permanent context maintenance).

**Architecture:** Monorepo with `git-subdir` source type. Marketplace manifest at root, both plugins in `plugins/` subdirectories. Each plugin is self-contained with skills, commands, references, and (for forge-keeper) hooks and scripts.

**Tech Stack:** Markdown (skills, commands, references), JSON (manifests, hooks), Bash (context watcher scripts)

**Design Spec:** `docs/superpowers/specs/2026-03-29-dev-forge-marketplace-design.md`

---

## File Structure

```
dev-forge/
├── .claude-plugin/
│   └── marketplace.json                ← NEW: marketplace registry
├── plugins/
│   ├── forge-init/
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json             ← NEW: plugin manifest
│   │   ├── skills/
│   │   │   └── forge-init/
│   │   │       ├── SKILL.md            ← NEW: main skill
│   │   │       └── references/
│   │   │           ├── claudemd-conventions.md  ← NEW: creation guide
│   │   │           └── manual-discovery.md      ← NEW: fallback procedure
│   │   └── commands/
│   │       └── init.md                 ← NEW: /forge-init:init
│   └── forge-keeper/
│       ├── .claude-plugin/
│       │   └── plugin.json             ← NEW: plugin manifest
│       ├── skills/
│       │   └── forge-keeper/
│       │       ├── SKILL.md            ← NEW: main skill (semantic trigger)
│       │       └── references/
│       │           ├── claudemd-guide.md        ← NEW: maintenance guide
│       │           └── monorepo-patterns.md     ← NEW: monorepo patterns
│       ├── commands/
│       │   ├── sync.md                 ← NEW: /forge-keeper:sync
│       │   └── status.md              ← NEW: /forge-keeper:status
│       ├── hooks/
│       │   └── hooks.json              ← NEW: UserPromptSubmit hook
│       └── scripts/
│           ├── context-watch.sh        ← NEW: git activity monitor
│           └── reset-watch.sh          ← NEW: state reset
├── README.md                           ← MODIFY: update with final structure
└── LICENSE                             ← EXISTS: no changes
```

---

## Task 1: Marketplace scaffold and manifest

**Files:**
- Create: `.claude-plugin/marketplace.json`

- [ ] **Step 1: Create directory structure**

```bash
mkdir -p .claude-plugin
mkdir -p plugins/forge-init/.claude-plugin
mkdir -p plugins/forge-init/skills/forge-init/references
mkdir -p plugins/forge-init/commands
mkdir -p plugins/forge-keeper/.claude-plugin
mkdir -p plugins/forge-keeper/skills/forge-keeper/references
mkdir -p plugins/forge-keeper/commands
mkdir -p plugins/forge-keeper/hooks
mkdir -p plugins/forge-keeper/scripts
```

- [ ] **Step 2: Create marketplace.json**

Create `.claude-plugin/marketplace.json`:

```json
{
  "name": "dev-forge",
  "owner": {
    "name": "dmedina",
    "email": "me@dmedina.dev"
  },
  "metadata": {
    "description": "Dev Forge — opinionated Claude Code plugins for project bootstrapping and ongoing context maintenance.",
    "version": "1.0.0"
  },
  "plugins": [
    {
      "name": "forge-init",
      "description": "Two-step project bootstrapper: runs native /init, then layers conventions.",
      "source": {
        "source": "git-subdir",
        "url": "https://github.com/dmedina-dev/dev-forge.git",
        "path": "plugins/forge-init"
      },
      "version": "1.0.0"
    },
    {
      "name": "forge-keeper",
      "description": "Keeps CLAUDE.md, docs and memories in sync across sessions.",
      "source": {
        "source": "git-subdir",
        "url": "https://github.com/dmedina-dev/dev-forge.git",
        "path": "plugins/forge-keeper"
      },
      "version": "1.0.0"
    }
  ]
}
```

- [ ] **Step 3: Validate JSON syntax**

Run: `cat .claude-plugin/marketplace.json | python3 -m json.tool > /dev/null && echo "VALID" || echo "INVALID"`
Expected: `VALID`

- [ ] **Step 4: Commit**

```bash
git add .claude-plugin/marketplace.json
git commit -m "feat: add marketplace manifest with forge-init and forge-keeper plugins"
```

---

## Task 2: forge-init plugin manifest

**Files:**
- Create: `plugins/forge-init/.claude-plugin/plugin.json`

- [ ] **Step 1: Create plugin.json**

Create `plugins/forge-init/.claude-plugin/plugin.json`:

```json
{
  "name": "forge-init",
  "version": "1.0.0",
  "description": "Two-step project bootstrapper. Step 1: runs the native /init interview to generate base config. Step 2: layers opinionated conventions — CLAUDE.md best practices, path-scoped rules, docs scaffolding. Designed to be uninstalled after use.",
  "author": {
    "name": "dmedina",
    "email": "me@dmedina.dev"
  },
  "repository": "https://github.com/dmedina-dev/dev-forge",
  "license": "MIT",
  "keywords": ["bootstrap", "init", "scaffold", "claude-md", "setup", "conventions"]
}
```

- [ ] **Step 2: Validate JSON syntax**

Run: `cat plugins/forge-init/.claude-plugin/plugin.json | python3 -m json.tool > /dev/null && echo "VALID" || echo "INVALID"`
Expected: `VALID`

- [ ] **Step 3: Commit**

```bash
git add plugins/forge-init/.claude-plugin/plugin.json
git commit -m "feat(forge-init): add plugin manifest"
```

---

## Task 3: forge-init SKILL.md

**Files:**
- Create: `plugins/forge-init/skills/forge-init/SKILL.md`

- [ ] **Step 1: Create SKILL.md**

Create `plugins/forge-init/skills/forge-init/SKILL.md`:

````markdown
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

forge-keeper is active for ongoing maintenance.
Run /forge-keeper:status to check context health anytime.
```

## Reference files

For CLAUDE.md conventions → read `references/claudemd-conventions.md`
For manual discovery fallback → read `references/manual-discovery.md`
````

- [ ] **Step 2: Verify frontmatter structure**

Run: `head -8 plugins/forge-init/skills/forge-init/SKILL.md`
Expected: YAML frontmatter with `name` and `description` fields between `---` delimiters.

- [ ] **Step 3: Commit**

```bash
git add plugins/forge-init/skills/forge-init/SKILL.md
git commit -m "feat(forge-init): add main skill with two-step bootstrap procedure"
```

---

## Task 4: forge-init reference — claudemd-conventions.md

**Files:**
- Create: `plugins/forge-init/skills/forge-init/references/claudemd-conventions.md`

- [ ] **Step 1: Create claudemd-conventions.md**

Create `plugins/forge-init/skills/forge-init/references/claudemd-conventions.md`:

```markdown
# CLAUDE.md Conventions — Creation Guide

Reference for forge-init's conventions layer. Use this when auditing and
improving CLAUDE.md files generated by /init.

## The ~200 Line Rule

Root CLAUDE.md should stay under ~200 lines. Research shows adherence drops
below 70% when CLAUDE.md exceeds this threshold — Claude starts ignoring or
misapplying instructions buried in long files.

Child CLAUDE.md files (per-directory) should stay under ~100 lines. They
supplement the root, they don't repeat it.

If you're over the limit, prune. If you can't prune enough, use @imports
for progressive disclosure.

## WHY / WHAT / HOW Structure

Organize CLAUDE.md content in this priority order:

**WHY** — Project purpose, key constraints, non-obvious decisions.
This is the most valuable section. A new Claude session needs to understand
WHY things are the way they are before it can make good decisions.

**WHAT** — Architecture, components, data flow, key directories.
What does this project contain and how do the parts relate?

**HOW** — Commands, workflows, conventions, gotchas.
How to build, test, deploy, and follow project conventions.

## Recommended Sections

Not every project needs all sections. Include what's relevant:

- **Stack** — Languages, frameworks, key dependencies. Only what's non-obvious
  or affects how Claude should write code.
- **Commands** — Build, test, lint, deploy. Exact commands, not descriptions.
  Include flags that matter (e.g., `npm test -- --coverage` not "run tests").
- **Architecture** — High-level structure. Which directories matter and why.
  How data flows. Where boundaries are.
- **Conventions** — Naming, patterns, code organization rules. Only project-
  specific ones — don't repeat language/framework defaults Claude already knows.
- **Gotchas** — Non-obvious traps. Things that break silently. Workarounds for
  known issues. These save the most time per line.
- **References** — @imports to longer docs, links to ADRs, API docs.

## What to Include

- Conventions that are surprising or project-specific
- Commands with exact flags and expected behavior
- Architectural decisions that constrain implementation choices
- Known bugs, workarounds, and non-obvious failure modes
- Environment setup that deviates from standard tooling
- Testing patterns specific to this project

## What to Exclude

- Anything Claude already knows (language syntax, standard library APIs,
  common framework patterns)
- Linter/formatter rules (Claude reads config files directly)
- Individual file descriptions (Claude can read files on demand)
- Generic best practices (e.g., "write clean code", "use meaningful names")
- Dependency lists (Claude reads package.json/requirements.txt)
- Version numbers (they change; Claude reads lock files)

## @imports for Progressive Disclosure

When CLAUDE.md would exceed the line limit, use @imports to reference
longer documents:

```
For testing conventions see @docs/testing-guide.md
For API patterns see @docs/api-conventions.md
```

Claude loads imported files lazily — only when working in a relevant context.
This keeps the main CLAUDE.md focused while preserving access to detailed
guidance.

## Child CLAUDE.md Files

Per-directory CLAUDE.md files are loaded lazily when Claude works in that
directory. Design them with these rules:

- **Supplement the root, never override it.** If root says "use Jest",
  a child should not say "use Vitest" without explicit reasoning.
- **Be specific to this directory's concerns.** A `domains/auth/CLAUDE.md`
  should cover auth-specific patterns, not repeat project-wide conventions.
- **Cross-reference, don't duplicate.** Point to root or @imports for
  shared conventions.
- **Keep under ~100 lines.** If you need more, split into @imports.

## Specific and Verifiable Instructions

Every instruction in CLAUDE.md should be specific enough that you can
verify whether Claude followed it. Compare:

❌ Vague: "Follow good testing practices"
✅ Specific: "Every public function needs a test. Tests go in `__tests__/`
adjacent to the source file. Use `describe/it` blocks, not `test()`."

❌ Vague: "Handle errors properly"
✅ Specific: "Domain errors extend `DomainError`. Infrastructure errors
extend `InfraError`. Never catch and swallow — always log or rethrow."

❌ Vague: "Keep code clean"
✅ Specific: "Max 1 level of callback nesting. Extract to named functions."

## Pruning Guidelines

When CLAUDE.md grows beyond limits, prune in this order:

1. **Remove what Claude already knows** — standard patterns, common APIs
2. **Remove what's in config files** — linter rules, tsconfig settings
3. **Merge similar instructions** — combine related conventions
4. **Move detail to @imports** — keep the summary, link to the full guide
5. **Remove oldest/most obvious** — conventions the team has internalized

Never prune gotchas or non-obvious decisions. These have the highest
value-per-line ratio.
```

- [ ] **Step 2: Verify file exists and has content**

Run: `wc -l plugins/forge-init/skills/forge-init/references/claudemd-conventions.md`
Expected: ~120 lines

- [ ] **Step 3: Commit**

```bash
git add plugins/forge-init/skills/forge-init/references/claudemd-conventions.md
git commit -m "feat(forge-init): add CLAUDE.md conventions reference guide"
```

---

## Task 5: forge-init reference — manual-discovery.md

**Files:**
- Create: `plugins/forge-init/skills/forge-init/references/manual-discovery.md`

- [ ] **Step 1: Create manual-discovery.md**

Create `plugins/forge-init/skills/forge-init/references/manual-discovery.md`:

```markdown
# Manual Discovery — Fallback Procedure

Use this when the native /init with `CLAUDE_CODE_NEW_INIT=1` is unavailable
or doesn't work. This procedure replicates what /init does through manual
codebase scanning and developer interview.

## Phase 1: Scan project structure

Map the project layout to understand what you're working with.

### 1.1 Root-level scan

Read the project root and identify:
- Package manager: `package.json` (npm/yarn/pnpm), `Cargo.toml`, `go.mod`,
  `pyproject.toml`, `pom.xml`, `build.gradle`
- Workspace config: `pnpm-workspace.yaml`, `package.json` workspaces field,
  `Cargo.toml` workspace members, `nx.json`, `turbo.json`
- Build system: `tsconfig.json`, `webpack.config.*`, `vite.config.*`,
  `next.config.*`, `Makefile`, `Dockerfile`
- CI/CD: `.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`
- Existing Claude config: `CLAUDE.md`, `.claude/`, `.claude/rules/`

### 1.2 Tech stack detection

From the package manager config, extract:
- Language(s) and version constraints
- Framework(s): React, Next.js, NestJS, Express, Django, FastAPI, etc.
- Key dependencies that affect code patterns (ORMs, state management,
  testing frameworks)
- Dev dependencies that indicate conventions (linters, formatters, type
  checkers)

### 1.3 Directory mapping

For each top-level directory, determine:

| Directory | Responsibility | Needs CLAUDE.md? |
|-----------|---------------|------------------|
| apps/     | Application packages | Yes — one per app |
| domains/  | Domain logic | Yes — DDD patterns |
| shared/   | Shared libraries | Yes — cross-cutting impact |
| infra/    | Infrastructure | Yes — deploy commands |
| scripts/  | Utility scripts | Probably not |
| docs/     | Documentation | No |

For monorepos, go one level deeper into workspace directories.

### 1.4 Existing conventions detection

Look for evidence of existing conventions:
- `.eslintrc*`, `.prettierrc*`, `biome.json` → code style (don't duplicate)
- `jest.config.*`, `vitest.config.*` → testing setup
- `.husky/`, `.lint-staged*` → git hooks
- `tsconfig.*.json` → TypeScript profiles
- `.env.example` → environment variables
- `docker-compose.yml` → service dependencies

## Phase 2: Interview the developer

Ask these questions one at a time. Use the answers to generate CLAUDE.md content.

### Essential questions

1. **What does this project do?** (One sentence — becomes the WHY section opening)

2. **What's the development workflow?**
   - How do you run it locally?
   - How do you run tests?
   - How do you deploy?
   (Becomes the Commands section)

3. **What conventions does the team follow that aren't in linter config?**
   - Naming patterns for files, functions, components
   - Code organization rules
   - Error handling patterns
   - Import ordering preferences
   (Becomes the Conventions section)

4. **What are the biggest gotchas?**
   - Things that break silently
   - Non-obvious dependencies between parts
   - Workarounds for known issues
   - "I wish I'd known this when I started"
   (Becomes the Gotchas section)

5. **Are there any areas with unusual patterns?**
   - Legacy code with different conventions
   - Generated code that shouldn't be edited
   - External dependencies with quirks
   (Becomes per-directory CLAUDE.md content)

### Monorepo-specific questions

6. **How do packages depend on each other?** (Dependency graph for architecture)

7. **Are there shared conventions across packages, or does each have its own?**
   (Determines .claude/rules/ vs per-directory CLAUDE.md)

8. **Which packages are most actively developed?** (Prioritize CLAUDE.md there)

## Phase 3: Generate CLAUDE.md files

Using the scan results and interview answers:

### 3.1 Root CLAUDE.md

Write following the WHY/WHAT/HOW structure from `claudemd-conventions.md`.
Include:
- Project purpose (from question 1)
- Architecture overview (from directory mapping)
- Key commands (from question 2)
- Cross-cutting conventions (from question 3)
- Gotchas (from question 4)

Stay under ~200 lines. Use @imports for detail.

### 3.2 Per-directory CLAUDE.md

For each directory marked "Needs CLAUDE.md" in the mapping:
- Write directory-specific conventions
- Reference root for shared conventions
- Include stack-specific commands if different from root
- Stay under ~100 lines

### 3.3 Present all generated files

Show the developer everything before writing:
- Root CLAUDE.md content
- Each per-directory CLAUDE.md
- Summary of what was detected vs what was asked

**DO NOT write files until the developer confirms.**
```

- [ ] **Step 2: Verify file exists and has content**

Run: `wc -l plugins/forge-init/skills/forge-init/references/manual-discovery.md`
Expected: ~120 lines

- [ ] **Step 3: Commit**

```bash
git add plugins/forge-init/skills/forge-init/references/manual-discovery.md
git commit -m "feat(forge-init): add manual discovery fallback procedure"
```

---

## Task 6: forge-init command

**Files:**
- Create: `plugins/forge-init/commands/init.md`

- [ ] **Step 1: Create init.md**

Create `plugins/forge-init/commands/init.md`:

```markdown
---
description: Two-step project bootstrapper. Step 1: runs native /init interview for base config. Step 2: layers dev-forge conventions — CLAUDE.md improvements, path-scoped rules, docs scaffolding. Uninstall after use.
---

Run the forge-init skill to bootstrap this project for Claude Code.

This is a guided two-step process:

Step 1 — Foundation:
  Run the native /init with interview mode (CLAUDE_CODE_NEW_INIT=1).
  This scans your codebase and interviews you about workflows and preferences.

Step 2 — Conventions:
  Audit and improve /init's output with dev-forge best practices:
  - CLAUDE.md quality (200-line limit, WHY/WHAT/HOW structure)
  - Per-directory CLAUDE.md for zones /init may have missed
  - Path-scoped .claude/rules/ for cross-cutting conventions
  - Documentation scaffolding (docs/sessions/, docs/adr/)
  - Personal overrides file (CLAUDE.local.md)

All changes require your explicit approval before being applied.

After initialization, uninstall this plugin:
  /plugin → Manage and uninstall plugins → forge-init → Uninstall
```

- [ ] **Step 2: Verify frontmatter**

Run: `head -3 plugins/forge-init/commands/init.md`
Expected: `---`, `description:` line, `---`

- [ ] **Step 3: Commit**

```bash
git add plugins/forge-init/commands/init.md
git commit -m "feat(forge-init): add /forge-init:init command entry point"
```

---

## Task 7: forge-keeper plugin manifest

**Files:**
- Create: `plugins/forge-keeper/.claude-plugin/plugin.json`

- [ ] **Step 1: Create plugin.json**

Create `plugins/forge-keeper/.claude-plugin/plugin.json`:

```json
{
  "name": "forge-keeper",
  "version": "1.0.0",
  "description": "Keeps CLAUDE.md, project docs and memories in sync after development sessions. Context-aware semantic detection plus explicit /sync command for human-driven updates. Safety-net git-based hook at relaxed thresholds.",
  "author": {
    "name": "dmedina",
    "email": "me@dmedina.dev"
  },
  "repository": "https://github.com/dmedina-dev/dev-forge",
  "license": "MIT",
  "keywords": ["memory", "context", "session", "documentation", "claude-md", "monorepo"]
}
```

- [ ] **Step 2: Validate JSON syntax**

Run: `cat plugins/forge-keeper/.claude-plugin/plugin.json | python3 -m json.tool > /dev/null && echo "VALID" || echo "INVALID"`
Expected: `VALID`

- [ ] **Step 3: Commit**

```bash
git add plugins/forge-keeper/.claude-plugin/plugin.json
git commit -m "feat(forge-keeper): add plugin manifest"
```

---

## Task 8: forge-keeper SKILL.md

**Files:**
- Create: `plugins/forge-keeper/skills/forge-keeper/SKILL.md`

- [ ] **Step 1: Create SKILL.md**

Create `plugins/forge-keeper/skills/forge-keeper/SKILL.md`:

````markdown
---
name: forge-keeper
description: >
  Keeps CLAUDE.md, project documentation and memories in sync after development
  sessions. This skill should activate when detecting semantic context shifts:
  the conversation moves between different domain areas (e.g., from auth to
  payments), shifts from frontend to backend or across monorepo zones, makes
  significant architectural decisions, or accumulates substantial changes that
  haven't been captured in project context. Also activates with explicit
  /forge-keeper:sync. Use when the user mentions "update context", "sync docs",
  "refresh CLAUDE.md", "session handoff", "save progress", or when you detect
  the conversation has drifted across multiple concerns without a sync.
---

# Forge Keeper

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
````

- [ ] **Step 2: Verify frontmatter structure**

Run: `head -12 plugins/forge-keeper/skills/forge-keeper/SKILL.md`
Expected: YAML frontmatter with `name` and `description` fields. Description should contain semantic trigger phrases.

- [ ] **Step 3: Commit**

```bash
git add plugins/forge-keeper/skills/forge-keeper/SKILL.md
git commit -m "feat(forge-keeper): add main skill with semantic trigger description"
```

---

## Task 9: forge-keeper reference — claudemd-guide.md

**Files:**
- Create: `plugins/forge-keeper/skills/forge-keeper/references/claudemd-guide.md`

- [ ] **Step 1: Create claudemd-guide.md**

Create `plugins/forge-keeper/skills/forge-keeper/references/claudemd-guide.md`:

```markdown
# CLAUDE.md Maintenance Guide

Reference for forge-keeper's sync process. Use this when updating CLAUDE.md
files after development sessions.

## When to Update CLAUDE.md

Update when the session introduced:
- **New conventions** — a pattern was established that future sessions should follow
- **Changed commands** — build/test/deploy commands were modified
- **Architectural shifts** — new modules, changed boundaries, restructured directories
- **Gotchas discovered** — bugs found, workarounds needed, non-obvious behavior
- **Dependencies changed** — new libraries that affect code patterns

Do NOT update for:
- Routine code changes within existing patterns
- Bug fixes that don't reveal new gotchas
- File additions that follow existing conventions
- Dependency version bumps without pattern changes

## Incremental Update Process

### 1. Read the current CLAUDE.md

Before proposing changes, read the existing file completely. Understand
what's already documented and what's missing.

### 2. Identify what the session adds

Compare session changes against existing content:
- Is this genuinely new information?
- Does it modify something already documented?
- Does it make existing content obsolete?

### 3. Propose minimal changes

- **Add** new instructions only if they're non-obvious and recurring
- **Update** existing instructions if they've become stale
- **Remove** instructions that are no longer accurate
- **Never** just append — integrate into the right section

### 4. Respect line limits

After your changes, count lines:
- Root CLAUDE.md: ~200 lines max
- Child CLAUDE.md: ~100 lines max

If over limit, prune in this order:
1. Remove what Claude already knows from training
2. Remove what's duplicated from config files
3. Merge similar or overlapping instructions
4. Move detailed guidance to @imports
5. Remove the oldest or most well-established conventions

## What Makes a Good Update

Good CLAUDE.md updates share these qualities:

**Specific and verifiable:**
```
# Good: "API routes use kebab-case: /user-profiles, /auth-tokens"
# Bad: "Follow REST naming conventions"
```

**Actionable:**
```
# Good: "Run `pnpm db:migrate` before `pnpm dev` after pulling"
# Bad: "Make sure the database is up to date"
```

**Non-obvious:**
```
# Good: "The payments module uses a saga pattern — don't call
#        services directly, dispatch events through the saga"
# Bad: "Use dependency injection for services"
```

## Handling Conflicts

When a session's findings conflict with existing CLAUDE.md content:

1. **Verify the conflict is real** — read the code to confirm
2. **Update, don't append** — remove the old instruction, add the new one
3. **Add context** — explain why it changed if non-obvious
4. **Check children** — if root changed, verify children are still consistent

## Session Summary Format

Every sync should produce a session summary in `docs/sessions/`:

```
## Session: YYYY-MM-DD — [descriptive title]

### Changes made
- [Concrete list of what changed]

### Decisions taken
- [Decision]: [rationale]

### Current status
- Completed: [finished items]
- In progress: [partial items]
- Pending: [identified but not started]

### Context for next session
- [What a fresh Claude session needs to know to continue]
```

The "Context for next session" section is the most valuable. Write it
as if briefing a colleague who knows the codebase but wasn't in the room.

## Rules for .claude/rules/ Updates

Only propose new rules when:
- A convention applies to multiple directories (cross-cutting)
- The convention needs path scoping (different rules for different files)
- It's not already in a CLAUDE.md file

Rule frontmatter format:
```yaml
---
description: What this rule enforces
globs: **/*.test.ts, **/*.spec.ts
---
```

Prefer CLAUDE.md for directory-specific conventions. Use `.claude/rules/`
for cross-cutting patterns that span the project.
```

- [ ] **Step 2: Verify file exists and has content**

Run: `wc -l plugins/forge-keeper/skills/forge-keeper/references/claudemd-guide.md`
Expected: ~120 lines

- [ ] **Step 3: Commit**

```bash
git add plugins/forge-keeper/skills/forge-keeper/references/claudemd-guide.md
git commit -m "feat(forge-keeper): add CLAUDE.md maintenance reference guide"
```

---

## Task 10: forge-keeper reference — monorepo-patterns.md

**Files:**
- Create: `plugins/forge-keeper/skills/forge-keeper/references/monorepo-patterns.md`

- [ ] **Step 1: Create monorepo-patterns.md**

Create `plugins/forge-keeper/skills/forge-keeper/references/monorepo-patterns.md`:

```markdown
# Monorepo Patterns for CLAUDE.md

Reference for managing Claude Code context in monorepo projects.

## Root vs Child Scope

In a monorepo, CLAUDE.md files form a hierarchy:

```
CLAUDE.md                    ← project-wide: stack, architecture, shared commands
apps/api/CLAUDE.md           ← API-specific: endpoints, middleware, DB patterns
apps/web/CLAUDE.md           ← web-specific: components, routing, state
domains/CLAUDE.md            ← domain layer: DDD patterns, aggregate rules
shared/CLAUDE.md             ← shared libs: versioning, cross-package impact
```

### Root CLAUDE.md responsibilities
- Project purpose and architecture overview
- Shared commands (build all, test all, lint all)
- Cross-cutting conventions (error handling, logging, naming)
- Monorepo-specific gotchas (dependency hoisting, build order)
- @imports to detailed docs

### Child CLAUDE.md responsibilities
- Directory-specific stack and tooling
- Commands that differ from root (e.g., different test runner)
- Patterns unique to this zone
- Local gotchas and workarounds

### The supplement rule

Children supplement the root, they never override it. If root says
"use Prettier for formatting", a child should not contradict this.
If a child needs an exception, document the WHY explicitly.

## Lazy Loading Behavior

Claude Code loads CLAUDE.md files lazily:
- Root CLAUDE.md is always loaded
- Child CLAUDE.md files load when Claude reads or edits files in that directory
- Deep children (e.g., `apps/api/src/modules/auth/CLAUDE.md`) only load when
  working in that specific path

Design your CLAUDE.md hierarchy knowing that Claude may not have loaded
a child's context. Don't rely on child instructions for cross-cutting behavior.

## Path-Scoped Rules (.claude/rules/)

For conventions that apply to specific file patterns across the entire project,
use `.claude/rules/` with glob patterns:

```yaml
# .claude/rules/testing.md
---
description: Testing conventions for all test files
globs: **/*.test.ts, **/*.spec.ts, **/*.test.tsx
---

- Use describe/it blocks, not standalone test()
- Mock external services, never the database
- Each test file mirrors its source file path
- Use factories for test data, not inline literals
```

```yaml
# .claude/rules/security.md
---
description: Security rules for domain and auth code
globs: domains/**, shared/auth/**
---

- Never log PII (email, phone, tokens)
- All auth checks go through the AuthGuard — no inline token parsing
- Domain errors must not leak internal state to API responses
```

### When to use rules vs CLAUDE.md

| Scenario | Use |
|----------|-----|
| Convention specific to one directory | That directory's CLAUDE.md |
| Convention for a file pattern across dirs | `.claude/rules/` with globs |
| Project-wide convention | Root CLAUDE.md |
| Exception to a root convention | Child CLAUDE.md with explanation |

## Zone Detection

When classifying changes by zone, use the first path segment:

```
apps/api/src/users.ts     → zone: apps/api
apps/web/src/App.tsx       → zone: apps/web
domains/auth/entities.ts   → zone: domains
shared/utils/helpers.ts    → zone: shared
scripts/deploy.sh          → zone: scripts
```

For flat projects (no monorepo), treat the root as a single zone and
classify by concern instead (e.g., "routing", "models", "tests").

## claudeMdExcludes

Some directories should never have or trigger CLAUDE.md loading:

```json
// .claude/settings.json
{
  "claudeMdExcludes": [
    "node_modules",
    "dist",
    "build",
    ".next",
    "coverage",
    "generated"
  ]
}
```

Add directories that contain generated code, build artifacts, or
dependencies. This prevents Claude from loading irrelevant context.

## Conflict Resolution

When root and child CLAUDE.md have conflicting instructions:

1. **Root wins by default** — it sets project-wide standards
2. **Child can override with explicit justification** — document WHY
3. **If the override is common**, consider updating root instead
4. **If it's a cross-cutting pattern**, move to `.claude/rules/`

Example of justified override:
```markdown
# apps/legacy-api/CLAUDE.md

## Conventions
# NOTE: This module uses callbacks instead of async/await (root convention)
# because it depends on a legacy library that doesn't support promises.
# Migration tracked in JIRA-1234.
- Use callback pattern for all async operations in this module
- New code that doesn't touch the legacy library CAN use async/await
```
```

- [ ] **Step 2: Verify file exists and has content**

Run: `wc -l plugins/forge-keeper/skills/forge-keeper/references/monorepo-patterns.md`
Expected: ~130 lines

- [ ] **Step 3: Commit**

```bash
git add plugins/forge-keeper/skills/forge-keeper/references/monorepo-patterns.md
git commit -m "feat(forge-keeper): add monorepo patterns reference guide"
```

---

## Task 11: forge-keeper commands

**Files:**
- Create: `plugins/forge-keeper/commands/sync.md`
- Create: `plugins/forge-keeper/commands/status.md`

- [ ] **Step 1: Create sync.md**

Create `plugins/forge-keeper/commands/sync.md`:

```markdown
---
description: Syncs CLAUDE.md, rules, docs and memories with the current session's changes. Analyzes git diff, classifies by zone, proposes updates for human review.
---

Run the forge-keeper skill to synchronize project context.

Steps:
1. Analyze session changes via git diff
2. Classify changes by monorepo zone
3. Propose updates to affected CLAUDE.md files
4. Propose .claude/rules/ additions if new conventions emerged
5. Generate session summary
6. Present everything for human approval

DO NOT apply changes without explicit human confirmation.
```

- [ ] **Step 2: Create status.md**

Create `plugins/forge-keeper/commands/status.md`:

```markdown
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
```

- [ ] **Step 3: Verify frontmatter on both files**

Run: `head -3 plugins/forge-keeper/commands/sync.md && echo "---" && head -3 plugins/forge-keeper/commands/status.md`
Expected: Both files start with `---` / `description:` / `---`

- [ ] **Step 4: Commit**

```bash
git add plugins/forge-keeper/commands/sync.md plugins/forge-keeper/commands/status.md
git commit -m "feat(forge-keeper): add /sync and /status commands"
```

---

## Task 12: forge-keeper hooks and scripts

**Files:**
- Create: `plugins/forge-keeper/hooks/hooks.json`
- Create: `plugins/forge-keeper/scripts/context-watch.sh`
- Create: `plugins/forge-keeper/scripts/reset-watch.sh`

- [ ] **Step 1: Create hooks.json**

Create `plugins/forge-keeper/hooks/hooks.json`:

```json
{
  "description": "Context-aware safety net that monitors git activity and reminds to sync when thresholds are exceeded",
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash ${CLAUDE_PLUGIN_ROOT}/scripts/context-watch.sh",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

- [ ] **Step 2: Validate JSON syntax**

Run: `cat plugins/forge-keeper/hooks/hooks.json | python3 -m json.tool > /dev/null && echo "VALID" || echo "INVALID"`
Expected: `VALID`

- [ ] **Step 3: Create context-watch.sh**

Create `plugins/forge-keeper/scripts/context-watch.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="/tmp/forge-keeper"
STATE_FILE="$STATE_DIR/state.json"
MIN_FILES="${FK_MIN_FILES:-20}"
MIN_ZONES="${FK_MIN_ZONES:-3}"
COOLDOWN="${FK_COOLDOWN:-15}"

mkdir -p "$STATE_DIR"

# Gather session activity
CHANGED_FILES=$(git diff --name-only HEAD 2>/dev/null || true)
STAGED_FILES=$(git diff --name-only --cached 2>/dev/null || true)
ALL_FILES=$(printf '%s\n%s' "$CHANGED_FILES" "$STAGED_FILES" | sort -u | grep -v '^$' || true)
FILE_COUNT=$(echo "$ALL_FILES" | grep -c '.' 2>/dev/null || echo 0)

ZONES=$(echo "$ALL_FILES" | cut -d'/' -f1 | sort -u | grep -v '^$' || true)
ZONE_COUNT=$(echo "$ZONES" | grep -c '.' 2>/dev/null || echo 0)

# Load state
PROMPT_COUNT=1; LAST_REMINDER=0; LAST_FILE_COUNT=0
if [ -f "$STATE_FILE" ]; then
  PROMPT_COUNT=$(( $(grep -o '"prompt_count":[0-9]*' "$STATE_FILE" | grep -o '[0-9]*') + 1 ))
  LAST_REMINDER=$(grep -o '"last_reminder":[0-9]*' "$STATE_FILE" | grep -o '[0-9]*' || echo 0)
  LAST_FILE_COUNT=$(grep -o '"last_file_count":[0-9]*' "$STATE_FILE" | grep -o '[0-9]*' || echo 0)
fi

SINCE_LAST=$(( PROMPT_COUNT - LAST_REMINDER ))
NEW_ACTIVITY=$(( FILE_COUNT - LAST_FILE_COUNT ))
[ "$NEW_ACTIVITY" -lt 0 ] && NEW_ACTIVITY=0

# Decide
SHOULD_REMIND=false
if [ "$FILE_COUNT" -ge "$MIN_FILES" ] && [ "$ZONE_COUNT" -ge "$MIN_ZONES" ] && \
   [ "$SINCE_LAST" -ge "$COOLDOWN" ] && [ "$NEW_ACTIVITY" -gt 0 ]; then
  SHOULD_REMIND=true
fi

# Zone detail
ZONE_DETAIL=""
if [ "$SHOULD_REMIND" = true ]; then
  while IFS= read -r zone; do
    [ -z "$zone" ] && continue
    count=$(echo "$ALL_FILES" | grep -c "^${zone}/" 2>/dev/null || echo 0)
    ZONE_DETAIL="${ZONE_DETAIL}  - ${zone}/ (${count} files)\n"
  done <<< "$ZONES"
fi

# Save state
RV=$LAST_REMINDER; [ "$SHOULD_REMIND" = true ] && RV=$PROMPT_COUNT
cat > "$STATE_FILE" << STATEJSON
{"prompt_count":$PROMPT_COUNT,"last_reminder":$RV,"last_file_count":$FILE_COUNT,"zone_count":$ZONE_COUNT}
STATEJSON

# Emit
if [ "$SHOULD_REMIND" = true ]; then
  cat << EOF
{"message":"Context checkpoint — ${FILE_COUNT} files changed across ${ZONE_COUNT} zones:\n$(echo -e "$ZONE_DETAIL")\nConsider running /forge-keeper:sync to capture these changes. (Ignore if you're in the middle of something.)"}
EOF
fi
```

- [ ] **Step 4: Create reset-watch.sh**

Create `plugins/forge-keeper/scripts/reset-watch.sh`:

```bash
#!/usr/bin/env bash
rm -f /tmp/forge-keeper/state.json
echo '{"reset":true,"message":"Context watcher reset."}'
```

- [ ] **Step 5: Make scripts executable**

Run: `chmod +x plugins/forge-keeper/scripts/context-watch.sh plugins/forge-keeper/scripts/reset-watch.sh`

- [ ] **Step 6: Test context-watch.sh in a clean state**

Run: `rm -f /tmp/forge-keeper/state.json && cd /Users/dmedina/Factory/dev-forge && bash plugins/forge-keeper/scripts/context-watch.sh`
Expected: No output (thresholds not met). Exit code 0.

Run: `cat /tmp/forge-keeper/state.json`
Expected: JSON with `prompt_count`, `last_reminder`, `last_file_count`, `zone_count` fields.

- [ ] **Step 7: Test reset-watch.sh**

Run: `bash plugins/forge-keeper/scripts/reset-watch.sh`
Expected: `{"reset":true,"message":"Context watcher reset."}`

Run: `[ ! -f /tmp/forge-keeper/state.json ] && echo "CLEANED" || echo "STILL EXISTS"`
Expected: `CLEANED`

- [ ] **Step 8: Commit**

```bash
git add plugins/forge-keeper/hooks/hooks.json plugins/forge-keeper/scripts/context-watch.sh plugins/forge-keeper/scripts/reset-watch.sh
git commit -m "feat(forge-keeper): add context watcher hook and scripts"
```

---

## Task 13: Update README and final validation

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Update README.md**

Replace the current README.md with updated content reflecting the final implementation:

```markdown
# Dev Forge

A personal GitHub plugin marketplace for Claude Code built around one principle:
**the plugin provides procedures, the project provides knowledge.**

## The Engine / Fuel Separation

**Engine** (this marketplace): Generic, reusable plugins that know HOW to maintain
context. Update the engine once, all projects benefit.

**Fuel** (your project): CLAUDE.md files, `.claude/rules/`, `docs/sessions/`, ADRs.
Created by the plugins, version-controlled in your repo. Survives independently
of the plugins.

## Plugins

| Plugin | Purpose | Lifecycle |
|--------|---------|-----------|
| **forge-init** | Two-step bootstrapper: runs native `/init`, then layers conventions | Disposable — uninstall after use |
| **forge-keeper** | Keeps CLAUDE.md, docs, and memories in sync across sessions | Permanent |

## Installation

```bash
# Add marketplace (once per machine)
/plugin marketplace add dmedina-dev/dev-forge

# New project setup
/plugin install forge-init
/plugin install forge-keeper

# Bootstrap the project
/forge-init:init

# Uninstall forge-init after bootstrap
# /plugin → Manage and uninstall plugins → forge-init → Uninstall
```

## Usage

### forge-init

Run `/forge-init:init` in a new or existing project. It will:

1. **Foundation** — Run the native `/init` interview to generate base config
2. **Conventions** — Audit and improve with best practices:
   - CLAUDE.md quality (200-line limit, WHY/WHAT/HOW structure)
   - Per-directory CLAUDE.md for zones `/init` missed
   - Path-scoped `.claude/rules/` for cross-cutting conventions
   - Documentation scaffolding (`docs/sessions/`, `docs/adr/`)
   - Personal overrides (`CLAUDE.local.md`)

All changes require your approval. After bootstrap, uninstall forge-init.

### forge-keeper

Stays installed permanently. Three ways it activates:

- **Semantic detection** — Claude detects you've shifted context (e.g., from auth
  to payments) and suggests running `/forge-keeper:sync`
- **Explicit command** — Run `/forge-keeper:sync` anytime to capture session changes
- **Safety net hook** — Monitors git activity and reminds when thresholds are exceeded

Commands:
- `/forge-keeper:sync` — Analyze changes, propose CLAUDE.md updates, generate session summary
- `/forge-keeper:status` — Context health report with drift detection

## Configuration

### Environment variables (forge-keeper hook thresholds)

| Variable | Default | Description |
|----------|---------|-------------|
| `FK_MIN_FILES` | 20 | Minimum changed files to trigger reminder |
| `FK_MIN_ZONES` | 3 | Minimum zones touched to trigger reminder |
| `FK_COOLDOWN` | 15 | Minimum prompts between reminders |

### Team auto-install

Add to your project's `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "dev-forge": {
      "source": { "source": "github", "repo": "dmedina-dev/dev-forge" }
    }
  }
}
```

## Future Plugins

Each follows engine/fuel: procedures in the plugin, knowledge in the project.

- **ddd-scaffold** — Domain/bounded context boilerplate generation
- **nest-patterns** — NestJS module/service/controller conventions
- **test-guardian** — TDD/BDD workflow enforcement via hooks
- **deploy-checklist** — Pre-deployment verification skill

## License

MIT
```

- [ ] **Step 2: Validate full file tree**

Run: `find plugins -type f | sort`
Expected:
```
plugins/forge-init/.claude-plugin/plugin.json
plugins/forge-init/commands/init.md
plugins/forge-init/skills/forge-init/SKILL.md
plugins/forge-init/skills/forge-init/references/claudemd-conventions.md
plugins/forge-init/skills/forge-init/references/manual-discovery.md
plugins/forge-keeper/.claude-plugin/plugin.json
plugins/forge-keeper/commands/status.md
plugins/forge-keeper/commands/sync.md
plugins/forge-keeper/hooks/hooks.json
plugins/forge-keeper/scripts/context-watch.sh
plugins/forge-keeper/scripts/reset-watch.sh
plugins/forge-keeper/skills/forge-keeper/SKILL.md
plugins/forge-keeper/skills/forge-keeper/references/claudemd-guide.md
plugins/forge-keeper/skills/forge-keeper/references/monorepo-patterns.md
```

- [ ] **Step 3: Validate all JSON files**

Run: `for f in .claude-plugin/marketplace.json plugins/forge-init/.claude-plugin/plugin.json plugins/forge-keeper/.claude-plugin/plugin.json plugins/forge-keeper/hooks/hooks.json; do echo -n "$f: "; python3 -m json.tool "$f" > /dev/null 2>&1 && echo "VALID" || echo "INVALID"; done`
Expected: All `VALID`

- [ ] **Step 4: Validate all markdown files have frontmatter where expected**

Run: `for f in plugins/forge-init/skills/forge-init/SKILL.md plugins/forge-init/commands/init.md plugins/forge-keeper/skills/forge-keeper/SKILL.md plugins/forge-keeper/commands/sync.md plugins/forge-keeper/commands/status.md; do echo -n "$f: "; head -1 "$f" | grep -q '^---' && echo "HAS FRONTMATTER" || echo "MISSING FRONTMATTER"; done`
Expected: All `HAS FRONTMATTER`

- [ ] **Step 5: Commit**

```bash
git add README.md
git commit -m "docs: update README with final plugin documentation"
```

---

## Task 14: Integration smoke test

No files to create — this is a manual verification task.

- [ ] **Step 1: Test forge-init plugin loads**

Run: `claude --plugin-dir plugins/forge-init --print-plugins 2>&1 | head -20`
Expected: `forge-init` appears in the plugin list with its skills and commands.

If `--print-plugins` is not a valid flag, try:
```bash
claude --plugin-dir plugins/forge-init -p "List your available skills and commands that contain 'forge' or 'init' in the name" --max-turns 1
```
Expected: Response mentioning forge-init skill and /forge-init:init command.

- [ ] **Step 2: Test forge-keeper plugin loads**

Run: `claude --plugin-dir plugins/forge-keeper -p "List your available skills and commands that contain 'session' or 'keeper' in the name" --max-turns 1`
Expected: Response mentioning forge-keeper skill, /forge-keeper:sync, and /forge-keeper:status commands.

- [ ] **Step 3: Test both plugins together**

Run: `claude --plugin-dir plugins/forge-init --plugin-dir plugins/forge-keeper -p "List all skills and slash commands available from forge-init and forge-keeper plugins" --max-turns 1`
Expected: Response listing forge-init skill, forge-keeper skill, /forge-init:init, /forge-keeper:sync, /forge-keeper:status.

- [ ] **Step 4: Final commit with all validated**

```bash
git add -A
git status
# If there are any remaining untracked files, review and add them
git commit -m "feat: dev-forge v1.0.0 — marketplace with forge-init and forge-keeper plugins" --allow-empty
```
