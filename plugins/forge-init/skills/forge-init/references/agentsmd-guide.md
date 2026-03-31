# AGENTS.md Generation Guide

Reference for forge-init step 7. Generate a cross-tool AGENTS.md alongside
the Claude-specific CLAUDE.md.

## What is AGENTS.md

AGENTS.md is a vendor-neutral standard (Linux Foundation / Agentic AI Foundation)
for giving AI coding agents project instructions. Supported by Codex, Copilot,
Cursor, Windsurf, Amp, Jules, Devin, Kilo Code, and others. 60,000+ repos
already use it.

## Relationship with CLAUDE.md

```
CLAUDE.md  = AGENTS.md content + Claude-specific features
AGENTS.md  = universal subset that works everywhere
```

**Include in AGENTS.md:**
- Build/test/lint commands (exact, with flags)
- Architecture overview (directories, boundaries, data flow)
- Coding conventions (naming, patterns, organization)
- Gotchas and non-obvious behavior
- Testing patterns
- Security constraints

**Exclude from AGENTS.md (Claude-specific):**
- @imports and references to .claude/ paths
- Skill triggers and plugin references
- Hook configurations
- forge-keeper commands and workflows
- Session log references

## Format

Plain Markdown, no frontmatter. Structure:

```markdown
# AGENTS.md

## Stack
[Languages, frameworks, key deps]

## Commands
[Exact build/test/lint/deploy commands]

## Architecture
[High-level structure, boundaries, data flow]

## Conventions
[Naming, patterns, code organization rules]

## Gotchas
[Non-obvious traps, workarounds, known issues]
```

## Generation Process

1. Read the project's CLAUDE.md completely
2. Extract all tool-agnostic content (commands, conventions, architecture, gotchas)
3. Skip all Claude-specific features (@imports, skill triggers, hooks, plugins)
4. Write AGENTS.md at project root
5. Keep it under ~150 lines (same progressive-disclosure principle)

## Maintenance

forge-keeper's `/sync` should check if AGENTS.md exists and whether it has
drifted from CLAUDE.md. If CLAUDE.md conventions change, propose updating
AGENTS.md too. The sync proposal should include an "AGENTS.md" section
when relevant.
