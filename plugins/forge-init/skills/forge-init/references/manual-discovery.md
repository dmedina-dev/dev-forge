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
