## Session: 2026-04-29 — forge-mattpocock v2.3.0

### Changes shipped

- **New plugin `forge-mattpocock` v1.0.0** — 8 skills curated from `mattpocock/skills` (`b56795b`, MIT, no upstream tags so pinned at HEAD of `main`).
  - `grill-me`, `tdd`, `diagnose`, `zoom-out`, `caveman` — copied unmodified.
  - `grill-with-docs` and `improve-codebase-architecture` — domain-glossary references rewired from upstream's `CONTEXT.md` / `CONTEXT-FORMAT.md` to dev-forge's `docs/glossary.md` / `GLOSSARY-FORMAT.md` (with CLAUDE.md and `.claude/rules/` recognised as adjacent surfaces).
  - `to-prd` — removed all GitHub / issue-tracker assignment; output is a wave-organized plan saved to `docs/plans/YYYY-MM-DD-<slug>.md` (parallel within a wave, sequential between waves, like `forge-superpowers:writing-plans`).
  - Excluded with one-line reasons in `.claude-plugin/customizations.json`: `triage` and `to-issues` (issue-tracker workflows with no value without an issue stream); `write-a-skill` (overlaps with `claude-plugins-official:skill-creator`); `git-guardrails-claude-code` (overlaps with `forge-security` + `forge-hookify`); `setup-pre-commit` (Husky/JS-only, too narrow for dev-forge's multi-stack profile); `migrate-to-shoehorn` and `scaffold-exercises` (Pocock-specific tooling); `setup-matt-pocock-skills` (per-skill setup helper inlined into the skills that needed it).

- **`forge-init` 1.1.0 → 1.1.1** — `commands/install-all.md` regenerated to include forge-mattpocock.

- **`scripts/generate-install-all.sh`** — fixed latent `dependencies`-shape bug (was reading `{"required":[]}` from the pre-v2.2.1 schema; the flip to flat array in v2.2.1 left the script broken on any marketplace with non-empty dependencies — `forge-brainstorming` would have crashed it on next run).

- **`marketplace.json` 2.2.1 → 2.3.0** (minor — added a new plugin).

- **README, CLAUDE.md, `docs/dependencies.md`** updated with the new plugin and `mattpocock/skills` attribution.

### Decisions taken

- **Side-by-side framework experiment.** `forge-mattpocock` and `forge-superpowers` ship together. There are no skill-name collisions (Pocock: `tdd`, `diagnose`, `grill-with-docs`; Superpowers: `test-driven-development`, `systematic-debugging`, `brainstorming`). Trigger by description match; scope per session via `forge-profiles` if you want only one.

- **`triage` deliberately excluded.** Reasoned with the user: the skill is fundamentally an issue-tracker state machine (list → label → comment → close). Without a stream of incoming issues, it has nothing to chew on. The patterns it carried (durable agent briefs, `.out-of-scope/` knowledge base) remain useful in isolation; we may break them out into a separate plugin if a use case appears.

- **`improve-codebase-architecture` added on second-pass review.** Completes the engineering trinity — `tdd` (build new), `diagnose` (fix broken), `improve-codebase-architecture` (improve existing). Vocabulary aligns with the deep-modules concept already in the `tdd` skill.

- **`zoom-out` and `caveman` added as cheap orthogonal extras.** `zoom-out` is 4 lines; `caveman` is opt-in via explicit triggers ("caveman mode" / "be brief") so no risk of accidental activation.

- **External-skill origin attribution format formalised.** Single-line HTML comment after the YAML frontmatter — invisible in rendered markdown, searchable in source. `.claude/rules/plugin-authoring.md` updated with the exact format.

- **Marketplace bumped MINOR (not patch).** A new plugin is a new feature surface for consumers, not a fix; minor is the right notch.

### Context for next session

- If the `forge-mattpocock` skills underperform vs `forge-superpowers` in real use, run `claude-plugins-official:skill-creator` evals to compare descriptions head-to-head. The skills with the largest framing differences (`tdd`'s "vertical slices, not horizontal", `diagnose`'s "build a feedback loop first") are the highest-leverage A/B candidates.

- The `.upstream/mattpocock-skills/` clone is HEAD-of-main pinned (no upstream tags). `forge-keeper:update-check` should treat it as commit-tracked, not tag-tracked.

- This sync also fixed pre-existing drift in `docs/dependencies.md` — `forge-frontend-design` had a matrix row but no section; `forge-ui-forge` was missing both. Now both have section + matrix entries. If you find similar drift in future syncs, the pattern is: matrix rows tend to be auto-padded but sections rot — grep `^### forge-` against the marketplace plugin list before claiming docs are in sync.

- The `dependencies`-shape gotcha is now in CLAUDE.md as a separate bullet from the original v2.2.1 fix. The original captured "use a flat array"; the new one captures "audit every script reader when changing a reserved-field shape". Same root cause, different lesson.
