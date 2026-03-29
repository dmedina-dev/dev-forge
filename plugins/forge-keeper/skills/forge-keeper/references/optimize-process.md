# Optimize Process

Reference for `/forge-keeper:optimize`. Use this when doing a deep audit
of project fuel against current engine capabilities.

## When to run

- After `/plugin marketplace update` delivers new dev-forge capabilities
- When the user notices their project config feels behind current best practices
- Periodically as a deep health check (e.g., monthly)

## How it differs from sync

| | forge-keeper:sync | forge-keeper:optimize |
|---|---|---|
| Trigger | Session changes / semantic drift | Plugin update / manual |
| Scope | Incremental — what this session added | Deep — full audit against current engine |
| Frequency | Per session | Per plugin update |
| Compares | Code changes vs existing CLAUDE.md | Project fuel vs engine capabilities |

## Execution model

Same as sync — run as a subagent or teammate to avoid polluting the user's
working context. Only the upgrade proposal returns to the main conversation.

## Audit procedure

### Step 1: Detect current engine capabilities

Read the forge-init SKILL.md and references to understand what the current
engine version offers. Build a checklist of features:

- CLAUDE.md with WHY/WHAT/HOW structure
- Per-directory CLAUDE.md files
- `.claude/rules/` with path-scoped globs
- `docs/sessions/` session summaries
- `docs/adr/` architecture decision records
- `CLAUDE.local.md` personal overrides
- `docs/exemplars.md` code exemplars
- @imports for progressive disclosure

### Step 2: Audit project fuel

For each capability in the checklist, check whether the project has it:

**Missing entirely:**
- Feature not present at all (e.g., no `docs/exemplars.md`)
- Propose creation with the user's input

**Present but outdated:**
- Feature exists but follows old conventions
- E.g., CLAUDE.md over 200 lines, missing WHY/WHAT/HOW structure
- Propose restructuring

**Present and current:**
- Feature exists and follows current conventions
- No action needed — include in "No changes needed" section

### Step 3: Check structural quality

Beyond feature presence, check quality:

- Root CLAUDE.md under ~200 lines?
- Child CLAUDE.md files under ~100 lines?
- `.claude/rules/` using globs frontmatter (not old `paths` format)?
- Session summaries following current template?
- ADRs using the standard template?
- Exemplars still pointing to valid files?

### Step 4: Check for deprecated patterns

Look for patterns the engine has moved away from:

- Old env var names (e.g., `SK_` prefix instead of `FK_`)
- References to `/session-keeper:` commands instead of `/forge-keeper:`
- Stale @imports pointing to moved/renamed docs
- Rules without glob frontmatter

### Step 5: Present upgrade proposal

Use the same structured proposal format as sync, but with an additional
"Upgrade" category:

```
## Optimize Proposal

### Upgrade (adopt new capabilities)
- Create `docs/exemplars.md` — code exemplars feature now available,
  recommend identifying reference files for [detected categories]
- Add @imports to CLAUDE.md — 3 sections could be extracted to reduce
  from 245 to ~180 lines

### Restructure (improve existing configuration)
- `CLAUDE.md` — reorganize into WHY/WHAT/HOW structure (currently flat)
- `.claude/rules/testing.md` — update frontmatter from `paths:` to `globs:`

### Migrate (fix deprecated patterns)
- Update env vars: SK_MIN_FILES → FK_MIN_FILES (if found in project config)
- Update command references: /session-keeper:* → /forge-keeper:*

### No changes needed
- `apps/api/CLAUDE.md` — follows current conventions ✓
- `docs/sessions/` — using current template ✓
- `.claude/rules/security.md` — current format ✓
```

## Key principles

- Optimize is opt-in — never runs automatically
- Every proposed change needs a WHY
- The user may decline upgrades — not every project needs every feature
- Preserve project-specific customizations — don't overwrite with defaults
- Run as subagent to avoid context pollution
