# 2026-05-26 — forge-ui-forge subagent delegation (v0.6.0 → v0.7.0)

## Why

The main Claude session was getting overwhelmed mid-flow when running `forge-ui-forge`:

- Phase 2 generates 12 HTML variants in `01-variations.html` — hundreds of KB.
- Phase 3 rewrites `02-forge.html` on every pin round; long sessions run 5–15 rounds.
- Phase 4 reads all rounds + 02-forge + templates to produce the bundle.

All three were happening in the parent context. By round 5 the session had lost track of brief/lock-ins/anti-patterns under a wall of HTML. The user asked to push these phases out to subagents the main session manages, so heavy artefacts never enter parent context.

## Decisions (with user)

1. **Scope of delegation**: Phases 2, 3, **and** 4. Phases 0/1/1.5 stay in the main session (lightweight, conversational).
2. **Paralelismo Phase 2**: single sequential subagent for all N variants. Not N parallel agents. Cheaper in tokens; latency tolerable.
3. **Auto-dispatch in Phase 3**: when Monitor surfaces `[ui-forge] round=N screen=X new=K ...`, the main session dispatches `ui-forge-iterator` immediately — no confirmation prompt. Asking would break the overlay-driven UX flow.
4. **Specialised agents, not generic**: three named agents (`ui-forge-variator`, `ui-forge-iterator`, `ui-forge-distiller`) instead of one generic dispatcher. Better triggers, sharper prompts.

## What changed

### New files
- `plugins/forge-ui-forge/agents/ui-forge-variator.md` — Phase 2 dispatcher
- `plugins/forge-ui-forge/agents/ui-forge-iterator.md` — Phase 3 dispatcher (auto-dispatched on Monitor line)
- `plugins/forge-ui-forge/agents/ui-forge-distiller.md` — Phase 4b dispatcher (runs `validate-bundle.sh` itself)

All three share the same skeleton: lock-in line · inputs contract · files-to-read list · precedence-charter compliance · output contract · ≤ 15-line structured report format. Tools: Read/Edit/Write/Bash/Grep/Glob. Model: sonnet. No nested Agent calls.

### Modified files
- `skills/ui-forge/SKILL.md` — Phase 2 / 3 / 4 sections rewritten to dispatch via Agent; new "Subagents" section; Quick checklist 7-9 updated; version 0.6.0 → 0.7.0
- `skills/ui-forge/references/subcommands.md` — § "On feedback event" describes auto-dispatch
- `.claude-plugin/plugin.json` — version 0.7.0
- `.claude-plugin/marketplace.json` (root) — entry forge-ui-forge to 0.7.0; description mentions subagents

### Context-offloading contract

The main session **never** passes HTML/JSON inline in the subagent prompt. It passes `screen-id` + `CWD` + small parameters; the subagent reads the files itself. Reports back ≤ 15 lines so the parent can show verbatim to the user.

For Phase 3, the SSE auto-reload watcher already disconnects file write from parent involvement: subagent writes `02-forge.html`, serve.py detects mtime change, browser reloads — main session is not in the path.

## Verification

- `python3 -m json.tool` on plugin.json and marketplace.json: ✅
- `bash scripts/marketplace-health.sh`: all 6 checks pass (18 plugin entries, paths, versions, dependencies shape, install-all parity)
- Manual end-to-end test pending — see the plan's § Verification (steps 1–5) for the runbook.

## Doc sync (applied in this session via /forge-keeper:sync)

- `README.md` line 73 — forge-ui-forge row mentions 3 subagents
- `docs/dependencies.md` § forge-ui-forge — explicit subagent list + delegation rationale
- `docs/exemplars.md` — new third exemplar "Native plugin with context-offloading subagents"
- `.claude/rules/plugin-authoring.md` — new bullet on paths-only subagent delegation (cross-references the exemplar)

## Discarded alternatives (recorded for future "why not?")

- **N parallel agents per variation**: rejected — more tokens, parent context savings are the same, latency win marginal.
- **Single generic `ui-forge-builder` agent that branches by phase**: rejected — vaguer description hurts auto-trigger, and prompts have to internally route. Specialisation is cheap, ambiguity is costly.
- **Confirmation prompt before dispatching iterator**: rejected — breaks the "user never leaves the browser" UX which is the whole value of the overlay loop.

## Next steps (not done)

- End-to-end smoke test in a real consumer project that already uses ui-forge.
- Token-usage comparison between 0.6.0 and 0.7.0 on the same iteration scenario (the success metric for this whole change).
- Optional v0.7.1 follow-up: dump the same approach onto `forge-deep-review` or any plugin that produces big artefacts in the parent context.
