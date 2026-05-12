# Session — Upstream sync, prototype-curation, dev-forge v2.4.0 → v2.6.0

**Dates:** 2026-05-11 → 2026-05-13
**Branch:** main
**Tags cut:** v2.5.0, v2.6.0
**HEAD at close:** `e556b35`

## Goal of this session

Run `/forge-keeper:update-check` to assess pending upstream changes across the 8 external plugins, then selectively absorb only what mattered: a real upstream sync for `forge-superpowers` (v5.0.7 → v5.1.0), metadata bookkeeping for everyone else, plus a curation pass over mattpocock's `prototype` and `handoff` skills — folding their insights into existing dev-forge plugins instead of vendoring whole.

## What landed

### Release v2.5.0 (commit `f7d9484`) — sync + bookkeeping

- **forge-superpowers 1.0.0 → 1.1.0**: applied obra/superpowers v5.0.7 → v5.1.0. 10 skill files refreshed (worktree rewrites in `using-git-worktrees` + `finishing-a-development-branch`; `requesting-code-review/code-reviewer.md` now embeds the deleted standalone agent's persona; modest updates to executing-plans, writing-plans, subagent-driven-development, systematic-debugging). 4 files deleted to mirror upstream removals: `commands/{brainstorm,execute-plan,write-plan}.md` (deprecated stubs) and `agents/code-reviewer.md` (merged into the skill). README refreshed. 6 new customization entries cataloguing AGENTS.md, CLAUDE.md, assets/, scripts/sync-to-codex-plugin.sh, .version-bump.json (all excluded), and `.claude-plugin/plugin.json` (now documented as locally modified). Local customizations preserved on hooks/hooks.json (custom-13), hooks/session-start (custom-14), and skills/brainstorming/SKILL.md trigger (custom-12).
- **forge-mattpocock 1.0.0 → 1.0.1** (review-only): 18 upstream commits inspected. Kept local divergences — `grill-with-docs` and `to-prd` carry intentional dev-forge adaptations (docs/glossary.md layout, wave-organized plans saved to docs/plans/) that aren't absorbable from upstream's minor wording tweaks. 9 new customization entries documenting 6 excluded upstream skills with reasons (prototype overlaps with forge-ui-forge, handoff with forge-keeper, in-progress/review with forge-deep-review, etc.).
- **forge-commit 1.1.1 → 1.1.2**: fixed `/forge-commit:release` aborting before its task body. Root cause: line-21 context loader used `for f in plugins/*/...` which zsh's `eval` rejected with `(eval):1: no matches found:` even though files existed. Replaced with `python3 -c "import glob; ..."` — single process, portable. Same pattern applied to step-5 verification block.
- **forge-{deep-review, frontend-design, hookify, plugin-dev, security} patch** (bookkeeping only): refreshed origin.commit pins to current main HEAD of upstream repos. 37/128 upstream commits inspected, zero touched any vendored plugin path. Also fixed `forge-frontend-design` `origin.path` from `frontend-design` (stale, never accurate) to `plugins/frontend-design`.

### Release v2.6.0 (commit `b4015d8`) — mattpocock curation absorbed

- **forge-keeper 1.3.1 → 1.4.0**: new `/forge-keeper:handoff [optional focus]` command. Writes a concise resumption note to `docs/sessions/YYYY-MM-DD-HHMM-handoff-<slug>.md` without touching CLAUDE.md/rules. Positioned as the **light** counterpart to `/forge-keeper:sync` (heavy). Idea curated from mattpocock/skills · `skills/productivity/handoff` (MIT); adapted to dev-forge's `docs/sessions/` convention so `/forge-keeper:recall` finds handoffs too, and to include git branch + last-commit SHA for receiver orientation.
- **forge-ui-forge 0.4.0 → 0.5.0** (behavior/logic capture, not just visual):
  - **Anti-pattern "wallpaper variants"** added to SKILL.md. Variants must disagree on structure (layout / hierarchy / primary affordance), not just colour or copy. Phrased from mattpocock/skills · `prototype/UI.md`.
  - **Phase 1.5 optional** `data/behavior.md` skeleton for stateful screens (wizards, state machines, mutation-heavy, complex validations). Inspired by mattpocock's `prototype/LOGIC.md` but adapted to ui-forge's HTML+Tailwind-only constraint — declarative markdown, not a runnable terminal TUI. Stand-alone logic-first prototyping deferred to a possible future `forge-logic-prototype` sibling plugin.
  - **`screen-spec.md.tmpl`** extended with a new `## Behavior` section containing 5 subsections: State transitions, Business rules, Validations, Mutation contracts, Conditional rendering. Distilled in Phase 4 from pins + optional behavior.md.
  - **`variations.html.tmpl`** focus-mode added: full-size single variant with `←` / `→` keyboard navigation, `F` to toggle, `Esc` to exit. Ignores key events when typing in inputs. Coexists with the existing grid scroll mode (default).
  - **`overlay.js`** gained 2 new pin types: `logic-rule` (gear / pink `#ec4899`) for business rules + per-field validations, and `state-transition` (cycle / cyan `#06b6d4`) for temporal/sequential behaviors. The original 5 types stay. Total 7, not 8 — explicitly discarded `validation` as a separate type because it's a subset of `logic-rule`; Phase 4 distillation splits them by heuristic (comment starts with `validación:` / `validation:` or names a field → § Validations; otherwise → § Business rules).
  - **`decision.md.tmpl`** new — Phase 4 captures the *rationale*, not just the result: winning variant + one-paragraph why + mix sources + one-line rejection per discarded variant. Inspired by mattpocock prototype's "capture the answer somewhere durable" rule.
- **README** gained a "Curated ideas adapted into other plugins" subsection in the mattpocock attribution block, documenting all 5 absorbed ideas with adaptation notes — discoverability for inspiration trails that land outside `forge-mattpocock`.

### Post-tag patch (commit `e556b35`) — heart → gear/cycle

Replaced heart emojis (🩷, 🩵) used in SKILL.md to disambiguate `logic-rule` and `state-transition` from the 5 original colored-circle pin types — pink and cyan circles don't exist in Unicode. Switched to functional symbols (⚙️ gear, 🔄 cycle) which carry semantic weight beyond colour. No version bump — purely cosmetic, lands on top of v2.6.0 without advancing the release.

## Open threads

- **`forge-logic-prototype`** as a possible sibling plugin to forge-ui-forge: would adapt mattpocock's `prototype/LOGIC.md` (terminal TUI driving a state machine by hand) for cases where the user wants to prove logic before designing UI. Out of scope for v2.6.0 — the declarative `behavior.md` skeleton (Phase 1.5) is the lighter alternative. Reconsider if the markdown skeleton turns out to under-deliver on complex state.
- **`/forge-ui-forge:refresh`** does not yet copy the updated `overlay.js` into existing consumer `.ui-forge/assets/` automatically when a plugin upgrade adds new pin types. Consumer projects on v0.4.0 → v0.5.0 will need a manual `refresh` invocation before the new pin types appear in their overlay.

## Next steps

1. **Test forge-ui-forge 0.5.0 end-to-end** in a real consumer project — bootstrap, generate variations, exercise focus mode + 2 new pin types, distill, verify `decision.md` and § Behavior land correctly.
2. **Test forge-keeper:handoff** in a real session — invoke without and with `$ARGUMENTS`, verify output structure, confirm `/forge-keeper:recall` picks it up next session.
3. Consider promoting `feedback_zsh_glob_slash_commands` learning into a `bash scripts/marketplace-health.sh` check that greps slash command `.md` files for `!`backtick`...for f in .*\*` patterns and warns.

## Skills to invoke next

- `/forge-ui-forge:ui-forge` — to validate v0.5.0 behavior capture
- `/forge-keeper:handoff` — to validate the new command itself
- `/forge-keeper:update-check` — next routine sync (no urgency — pins are fresh)

## References

- Tags: `v2.4.0` (session start) → `v2.5.0` (sync) → `v2.6.0` (curation)
- Commits: `8a6c22c`, `f7d9484`, `b4015d8`, `e556b35`
- Customizations updated: `plugins/forge-{commit,deep-review,frontend-design,hookify,mattpocock,plugin-dev,security,superpowers}/.claude-plugin/customizations.json`
- New artifacts: `plugins/forge-keeper/commands/handoff.md`, `plugins/forge-ui-forge/skills/ui-forge/templates/decision.md.tmpl`
- Upstream clones at: `.upstream/obra-superpowers` (@ v5.1.0 / f2cbfbe), `.upstream/mattpocock-skills` (@ 9f2e0bd), `.upstream/anthropics-claude-code` (clean), `.upstream/anthropics-claude-plugins-official` (clean)
