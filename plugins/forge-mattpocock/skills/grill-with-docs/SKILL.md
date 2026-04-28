---
name: grill-with-docs
description: Grilling session that challenges your plan against the project's existing documentation, sharpens domain terminology, and updates docs (CLAUDE.md, .claude/rules/, docs/glossary.md, docs/adr/, docs/exemplars.md) inline as decisions crystallise. Use when user wants to stress-test a plan against the project's language, captured conventions, or documented decisions.
disable-model-invocation: true
---

<!-- Curated from mattpocock/skills · skills/engineering/grill-with-docs/SKILL.md · MIT. Adapted to dev-forge's documentation structure (CLAUDE.md / .claude/rules/ / docs/glossary.md / docs/adr/ / docs/exemplars.md). -->

Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.

Ask the questions one at a time, waiting for feedback on each question before continuing.

If a question can be answered by exploring the codebase, explore the codebase instead.

## Documentation surface

Dev-forge projects keep documentation in a layered structure. Read whatever exists before starting — don't assume:

```
/
├── CLAUDE.md                  ← project conventions, architecture, gotchas (line-limited, ~200)
├── .claude/
│   └── rules/*.md             ← cross-cutting rules with file globs
├── docs/
│   ├── glossary.md            ← (optional, lazy) domain language — terms, relationships, ambiguities
│   ├── exemplars.md           ← canonical code examples
│   ├── adr/                   ← architecture decision records (0001-slug.md, 0002-slug.md, ...)
│   └── sessions/              ← session handoff notes
└── src/
    └── <zone>/
        └── CLAUDE.md          ← zone-scoped conventions (~100 lines)
```

Map of where to push each kind of finding during the grilling:

| Discovery | Lands in |
|-----------|----------|
| A new term, alias, or resolved ambiguity | `docs/glossary.md` (create lazily) |
| A new convention to apply across files matching a glob | `.claude/rules/<rule>.md` |
| A canonical, "do it like this" code example | `docs/exemplars.md` |
| A non-trivial architectural decision (see "ADR criteria") | `docs/adr/NNNN-slug.md` |
| A zone-specific convention or constraint | the zone's `CLAUDE.md` (or root if cross-cutting) |
| A gotcha that future sessions will trip on | the relevant CLAUDE.md `## Gotchas` section |

In zoned repos (where `src/<area>/CLAUDE.md` files exist), infer which zone the current topic belongs to. If unclear, ask.

Create files lazily — only when you have something to write. Don't scaffold empty `glossary.md` or `docs/adr/`.

## During the session

### Challenge against the glossary

When the user uses a term that conflicts with `docs/glossary.md` (or with a glossary section inside CLAUDE.md), call it out immediately. "The glossary defines `cancellation` as X, but you seem to mean Y — which is it?"

### Sharpen fuzzy language

When the user uses vague or overloaded terms, propose a precise canonical term. "You're saying `account` — do you mean the Customer or the User? Those are different things."

### Discuss concrete scenarios

When domain relationships are being discussed, stress-test them with specific scenarios. Invent edge-case scenarios that force the user to be precise about boundaries between concepts.

### Cross-reference with code

When the user states how something works, check whether the code agrees. If you find a contradiction, surface it: "The code cancels entire Orders, but you just said partial cancellation is possible — which is right?"

### Cross-reference with CLAUDE.md and rules

CLAUDE.md and `.claude/rules/` are the conventions layer. If a proposed direction conflicts with an existing rule or convention, surface the conflict. "CLAUDE.md says all DB writes go through the repository pattern, but the plan calls direct SQL — intentional exception, or did you forget?"

### Update the docs inline

When a term, rule, or decision is resolved, write it to its target right then. Don't batch — capture as it happens:

- Glossary terms → append to `docs/glossary.md` using the format in [GLOSSARY-FORMAT.md](./GLOSSARY-FORMAT.md). Keep it focused on **domain language meaningful to humans on the project** — not implementation details.
- Cross-cutting rules → write to `.claude/rules/<rule>.md` with the file glob the rule applies to.
- Architectural decisions that meet the ADR criteria below → `docs/adr/NNNN-slug.md` per [ADR-FORMAT.md](./ADR-FORMAT.md).
- Conventions specific to one zone → that zone's `CLAUDE.md`.

### Offer ADRs sparingly

Only offer to create an ADR when **all three** are true:

1. **Hard to reverse** — the cost of changing your mind later is meaningful.
2. **Surprising without context** — a future reader will wonder "why did they do it this way?"
3. **The result of a real trade-off** — there were genuine alternatives and you picked one for specific reasons.

If any of the three is missing, skip the ADR. A bug fix or routine refactor is not an ADR.

### Respect existing ADRs

If the plan touches an area that already has ADRs in `docs/adr/`, read them first. Surface any conflict between the plan and a prior decision, and ask whether the plan supersedes the ADR (in which case the prior ADR's status flips to `superseded by ADR-NNNN`).

## What does NOT belong in docs

Don't pollute the documentation layer with implementation noise:

- File paths or line numbers — they go stale
- Code examples that aren't canonical (those don't belong in `exemplars.md`)
- General programming concepts (timeouts, error handling, utility patterns)
- Anything that is already obvious from the code

The bar: removing the entry would confuse a future reader. If not, don't write it.
