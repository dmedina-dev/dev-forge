# forge-mattpocock

Engineering & productivity skills curated from [mattpocock/skills](https://github.com/mattpocock/skills) — an alternative skill framework to test alongside (or instead of) `forge-superpowers`.

## Attribution

Original author: **Matt Pocock** ([@mattpocock](https://github.com/mattpocock))

Upstream: <https://github.com/mattpocock/skills> (MIT) — pinned at commit `b56795b` on `main` (2026-04-28).

This bundle keeps all upstream content under the upstream MIT license. See `.claude-plugin/customizations.json` for every change applied on top of the original.

## Skills

| Skill | Origin | Adaptation |
|-------|--------|------------|
| `grill-me` | `skills/productivity/grill-me/` | as-is |
| `grill-with-docs` | `skills/engineering/grill-with-docs/` | rewired to forge-keeper docs (`CLAUDE.md`, `.claude/rules/`, `docs/glossary.md`, `docs/adr/`, `docs/exemplars.md`) |
| `to-prd` | `skills/engineering/to-prd/` | no issue tracker — outputs a wave-organized plan to `docs/plans/` |
| `tdd` | `skills/engineering/tdd/` | as-is |
| `diagnose` | `skills/engineering/diagnose/` | as-is |
| `improve-codebase-architecture` | `skills/engineering/improve-codebase-architecture/` | domain-glossary refs re-pointed at `docs/glossary.md` and `GLOSSARY-FORMAT.md` |
| `zoom-out` | `skills/engineering/zoom-out/` | as-is |
| `caveman` | `skills/productivity/caveman/` | as-is — ultra-compressed responses on demand |

The deliberately excluded skills (and why) are documented in `.claude-plugin/customizations.json`. Headlines: `triage` and `to-issues` are issue-tracker workflows we don't need; `write-a-skill` overlaps with the `claude-plugins-official:skill-creator` we already use; `git-guardrails-claude-code` overlaps with `forge-security` and `forge-hookify`; `setup-pre-commit` is JS-only.

## When to use

- You want a **lighter, more focused** skills set than `forge-superpowers`.
- You prefer Pocock's framing for **diagnose** (build a feedback loop first) and **TDD** (vertical slices, not horizontal).
- You want a **stress-test interview** that updates documentation inline (`grill-with-docs`).
- You want a **PRD-style plan** synthesized from the current conversation, organized by waves you can dispatch in parallel (`to-prd`).
- You want a disciplined **architecture-improvement** flow that finds shallow modules and proposes deepening refactors (`improve-codebase-architecture`).
- You want quick **orientation** in unfamiliar code (`zoom-out`).
- You want a **terse output mode** for token-heavy sessions (`caveman`).

## Coexistence with forge-superpowers

Both can be installed at the same time. There is no naming collision — Pocock's skills are `grill-me`, `grill-with-docs`, `to-prd`, `tdd`, `diagnose`, `improve-codebase-architecture`, `zoom-out`, `caveman`; superpowers' are `test-driven-development`, `systematic-debugging`, `writing-plans`, etc. Claude will trigger whichever skill description matches better. If you want only one framework active in a session, use `forge-profiles` to scope the active set.

## Independence

This plugin does not require any other dev-forge plugin. It pairs naturally with:

- **forge-keeper** — `grill-with-docs` writes into the same docs structure forge-keeper maintains.
- **forge-commit** — `tdd`'s "commit per cycle" rhythm fits `/commit`.
- **forge-deep-review** — run after a `tdd` cycle.

## License

MIT (matching the upstream `mattpocock/skills` license).
