# Knowledge Layer Principles

These principles govern how project knowledge is organized across the three
layers Claude Code uses: CLAUDE.md files, `.claude/rules/`, and memories.

## 1. DRY across knowledge layers

If the same information exists in a memory, a rule, and a CLAUDE.md — that's
a bug, not thoroughness. Consolidate to one authoritative place:

- **CLAUDE.md** — project/directory-specific context (architecture, commands, gotchas)
- **`.claude/rules/`** — cross-cutting conventions scoped by file pattern
- **Memories** — non-obvious context that code can't reveal (decisions, preferences, external systems)

When you find duplication, delete the less authoritative copy. CLAUDE.md is
the source of truth for project context. Rules are the source of truth for
conventions. Memories are the source of truth for human context.

## 2. Rules over memories for conventions

If a pattern applies every time code in a certain area is touched, it's a rule.
Rules load automatically via glob patterns — they don't require the developer
to remember to check them.

```
# This is a RULE (recurring, scoped to file pattern):
"Use describe/it blocks in all test files"
→ .claude/rules/testing.md with globs: **/*.test.ts

# This is a MEMORY (one-time decision with context):
"We chose Jest over Vitest because of X dependency"
→ memory file, not a rule
```

If you're unsure: will a future Claude session need this every time it touches
these files? → Rule. Does it explain a WHY that won't be obvious from the code? → Memory.

## 3. Memories for the non-obvious

Memories should capture what code and config files can't reveal:

**Good memory candidates:**
- Decisions with rationale ("we chose X because of Y constraint")
- User preferences and working style
- External system context (where bugs are tracked, which dashboard to check)
- Cross-project knowledge (what happened in another repo that affects this one)

**Bad memory candidates:**
- Anything derivable from reading code or git history
- Implementation details that live in the code itself
- Current branch or task state (ephemeral)
- File paths or function names (they change — grep instead)

The test: would a future Claude session benefit from this knowledge, AND could
it NOT discover it by reading code? Both must be true.

## 4. Lean over comprehensive

A 10-line rule that's always read beats a 100-line reference that's sometimes
skimmed. Claude's adherence drops below 70% when CLAUDE.md exceeds ~200 lines.

Implications:
- Root CLAUDE.md: ~200 lines max
- Child CLAUDE.md: ~100 lines max
- Rules: as short as possible — one concern per rule file
- Use @imports for progressive disclosure when detail is needed
- Prune aggressively — remove what Claude already knows, what's in config files,
  what the team has internalized

When in doubt, shorter is better. You can always add detail in a reference
file that loads on demand.

## 5. Path-scoped when possible

Rules with globs only load when Claude is working on matching files. This
saves context window space and reduces noise.

```yaml
# Good — loads only when touching test files:
---
globs: **/*.test.ts, **/*.spec.ts
---

# Less good — always in context even when irrelevant:
# (put this in the relevant directory's CLAUDE.md instead)
```

Similarly, child CLAUDE.md files load lazily — only when Claude reads or
edits files in that directory. Design your knowledge hierarchy knowing this:
- Cross-cutting → `.claude/rules/` with globs
- Directory-specific → that directory's CLAUDE.md
- Project-wide → root CLAUDE.md
- Deep detail → @import reference file

## Applying these principles

**During forge-init (creation):**
When deciding where to put a piece of knowledge, walk this decision tree:
1. Is it a recurring convention for specific file patterns? → Rule with globs
2. Is it specific to one directory? → That directory's CLAUDE.md
3. Is it project-wide context? → Root CLAUDE.md
4. Is it a non-obvious decision or preference? → Memory
5. Is it detailed guidance needed on demand? → Reference via @import

**During forge-keeper:sync (maintenance):**
When proposing updates, check:
- Am I duplicating something that already exists in another layer?
- Could this be a rule instead of a CLAUDE.md addition?
- Is this still under the line limits?
- Is this scoped as narrowly as possible?

**During forge-init (restructuring):**
Audit all three layers against these principles:
- Find and eliminate cross-layer duplication
- Promote recurring conventions from CLAUDE.md to rules
- Demote memories that are now obvious from the code
- Split oversized files using @imports
