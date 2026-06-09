---
name: ui-forge
description: >-
  Prototype full UI screens iteratively before implementing them in production code,
  maintaining a per-project catalog of reusable components and shared data fixtures under
  .ui-forge/. Hot-reload dev server with click-to-annotate overlay: the user annotates in
  the browser, clicks 🚀 Send to Claude, Claude regenerates the HTML and the browser
  reloads via SSE. Subcommands: "ui-forge serve" (start), "ui-forge stop", "ui-forge
  status". Use when the user wants to design or prototype a screen, explore visual
  variations, mockups or wireframes, gather inline feedback via annotations, build a
  reusable component library, or start/stop the ui-forge server. Also triggers on Spanish
  phrases like "prototipar la pantalla de", "diseña la UI de", "explora opciones visuales
  para", "quiero mockear", "necesito maquetar", "arranca ui-forge", "para el servidor".
  Do NOT use for bug fixes in existing UI, small CSS tweaks, or implementing an approved
  external design (Figma, Sketch).
version: 0.7.0
---

# ui-forge

Iterative prototyping workflow that lives entirely under `<project>/.ui-forge/`. Produces framework-agnostic specs and structured mock data that the downstream frontend-implementation agent consumes. **Never touches `src/` or framework code.**

## When to use

**Yes:**
- "Quiero prototipar la pantalla de X antes de implementarla"
- "Diseña la UI de [pantalla] reutilizando lo que ya tenemos"
- "Necesito explorar opciones visuales para [feature]"
- Any feature kickoff with non-trivial UI

**No:**
- Visual bug fixes on existing production code
- Point CSS edits
- When an externally-approved design (Figma, Zeplin) is ready to implement directly

## Precedence charter

<!-- Curated influence: nexu-io/open-design · apps/daemon/src/prompts/system.ts (composeSystemPrompt) · MIT.
     Open Design composes its system prompt from layered fragments (memory →
     user instructions → project instructions → design system → skill body →
     craft) with **precedence rules written into the prompt itself** — e.g.
     "brand wins on color, skill wins on workflow". That pattern of explicit,
     prompt-embedded precedence is what this charter ports into ui-forge.
     Adapted: ui-forge's three-axis model (visual/behavior/data + workflow
     meta) replaces Open Design's brand/skill model, and the seven rules are
     specific to the ui-forge phase loop. The phase-opening lock-in line is
     a ui-forge-native pattern, not from Open Design. -->

Every turn touches one or more of three axes — **visual**, **behavior**, **data** — over a workflow scaffold. When two layers disagree, follow this precedence. Phase 2 drift ("variants that differ in color but not structure"), Phase 3 axis-confusion ("user pinned a behavior but I tweaked CSS"), and Phase 4 spec leaks ("a field appears in the spec that isn't in the schema") usually come from skipping one of these rules.

| # | Rule | Wins over |
|---|---|---|
| 1 | **Workflow wins over speed.** Phases that say "ask before X" gate the next step. Skipping Phase 1.5 on a stateful screen, or Phase 4 confirmation on a new component, is never authorized by user pressure. | "andá ya", "no preguntes", "rápido" |
| 2 | **Catalog before invention.** If `registry/manifest.json` has a plausible candidate, propose reuse explicitly *before* designing new. State the reuse decision in writing — implicit reuse drifts to silent reinvention. | "creo que sería distinto", "mejor uno nuevo" |
| 3 | **Schema is the data contract.** A field that appears in HTML must exist in `data/schema.json`. If a variant needs a new field: modify schema → regenerate `mock.json` → render. Never inline data into HTML. | "lo necesito ya en el render" |
| 4 | **Behavior contract is authoritative for temporal logic.** Phase 2 affordances must reflect `behavior.md` when present — a "Save" button without a declared mutation is ambiguous, not decorative. | "se entiende el botón sin contrato" |
| 5 | **Tokens are authoritative for visual primitives.** Color, spacing, type, radii, shadows come from `registry/tokens.json`. Missing token → propose adding it to `tokens.json` first, then use it. Never inline hex or magic px. | "queda mejor con #fafafa raw" |
| 6 | **Pins are diffs, not full restatements.** A Phase 3 feedback round describes deltas against the current `02-forge.html`. Don't relitigate decisions from prior rounds unless an explicit pin reopens them. | "ya que estamos lo refactoreo todo" |
| 7 | **Brief defines scope.** What's outside the frozen `brief.md` stays out — even when it "would make sense to add". Scope creep belongs in a sibling screen brief, not in the current one. | "aprovecho que estoy acá y meto..." |

### Phase opening: lock-in line

At the start of each phase, post a short lock-in line so the user can intercept misreads **before** any generation happens. Format:

```
[ui-forge] phase=<n> workflow=<phase-name>
  manifest=<read|n/a>  brief=<frozen|pending>  schema=<validated|drafting|n/a>
  behavior=<n/a|skeleton-loaded|distilled>  tokens=<source>  axis=<visual|behavior|data|mixed>
```

Worked example (Phase 2 opening on `portfolio-overview` after Phase 1.5 ran):

```
[ui-forge] phase=2 workflow=variation-exploration
  manifest=read  brief=frozen  schema=validated
  behavior=skeleton-loaded  tokens=registry/tokens.json  axis=visual
```

If any field is wrong, the user corrects and you re-emit before doing the work. This is cheap — one line of output — and prevents 90% of "I generated 12 variants but the schema was missing a field" rounds.

## On-disk layout

Every consumer project gets:

```
<project>/.ui-forge/
├── config.json                       { "version": 1, "naming": "kebab-case" }
├── assets/
│   └── overlay.js                    copied from skill on first bootstrap
├── registry/
│   ├── manifest.json                 components catalog (growing over time)
│   ├── tokens.json                   design tokens (evolves explicitly)
│   ├── catalog.html                  browsable gallery
│   ├── fixtures/
│   │   ├── index.json
│   │   └── <name>.json
│   └── components/<id>/v1/{component.html, spec.md}
└── screens/<screen-id>/
    ├── brief.md
    ├── data/
    │   ├── schema.json               declarative: types, enums, ranges, count
    │   ├── mock.json                 materialized "happy" scenario
    │   └── scenarios/{empty,loading,error,happy,edge-*}.json
    ├── 01-variations.html
    ├── 02-forge.html
    ├── feedback/round-NN.json
    └── output/{screen.html, screen-spec.md, decision.md, components-used.json}
```

## Workflow — 5 phases

### Phase 0 — Bootstrap

Run the bootstrap script; it is idempotent. It creates the skeleton, seeds `tokens.json` with Tailwind defaults, and copies `overlay.js` into `.ui-forge/assets/` so downstream HTML files have a stable relative path to it.

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/ui-forge/scripts/init-registry.sh"
```

After bootstrap:
1. Read `registry/manifest.json`, `registry/tokens.json`, `registry/fixtures/index.json` to absorb prior state.
2. Ask the user for the screen brief if they haven't provided one.
3. Freeze the brief to `screens/<screen-id>/brief.md`. `<screen-id>` = kebab-case of the screen name.

On first run, briefly ask whether to adjust the default tokens before moving on.

### Phase 1 — Mock data

1. Infer `data/schema.json` declaratively from the brief and from the `Data contract` section of any registry component you plan to reuse. Schema has `entities.<name>` with either an `import` reference to a fixture or an inline `shape` + `count` spec. Example:
   ```json
   {
     "entities": {
       "portfolio": { "import": "registry/fixtures/portfolios.json", "select": "diego" },
       "transactions": {
         "shape": {
           "id": "uuid",
           "ticker": { "enum": ["IBE.MC", "SAN.MC", "TEF.MC", "ITX.MC"] },
           "amount": { "type": "number", "range": [100, 50000] },
           "date": { "type": "date", "range": ["2025-01-01", "today"] }
         },
         "count": { "default": 12, "edge-dense": 500, "empty": 0 }
       }
     }
   }
   ```

2. **Consult existing fixtures before generating new data.** If an entity can be satisfied by a fixture (`portfolios`, `users`, `products`…), propose reusing it. This keeps data coherent across screens.

3. Generate `data/mock.json` (the `happy` scenario) with data **plausible for the project domain** — not `lorem ipsum`. Tickers should look like real tickers, prices like real prices, names like real names.

4. Auto-generate `data/scenarios/{empty,loading,error}.json`. Generate `edge-*.json` only when declared or requested.

5. If during generation a dataset emerges that's clearly reusable (e.g., a market-indices list, a country list), **ask before promoting** it to `registry/fixtures/`.

### Phase 1.5 — Behavior skeleton (optional, only for stateful screens)

<!-- Curated influence: mattpocock/skills · skills/engineering/prototype/LOGIC.md · MIT.
     Adapted: instead of generating a runnable terminal TUI for the state model
     (mattpocock's approach), we capture the same concerns declaratively in a
     markdown skeleton that the user/LLM refines through Phases 2-4. This keeps
     the flow HTML+Tailwind-only and avoids adding a new runtime to ui-forge.
     An executable logic prototype would belong in a separate plugin (not
     built); out of scope for ui-forge. -->

**Activate this phase only when the screen has non-trivial logic.** Signals: wizard, multi-step form, dashboard with real-time updates, screen with state machine (loading → loaded → error → retry), form with cross-field validations, mutation-heavy screen (POST/PATCH/DELETE).

For read-only screens, simple displays, and one-shot forms, **skip this phase** — Phase 4's `## Behavior` section captures what little is needed from the pins.

If activated, generate `screens/<id>/data/behavior.md` from the brief with placeholders for:
- **State transitions** — `from → to (on <trigger>, after <timing>)`
- **Business rules** — invariants the UI must respect (cross-field, domain-level)
- **Validations** — per-field constraints (`required`, ranges, format)
- **Mutation contracts** — for each user-driven write: preconditions, effects, success path, error path
- **Conditional rendering** — rules beyond static scenarios (`if N > 100 → render pagination`)

Pre-fill from the brief; let the user refine. Phase 2 variants can reference this skeleton when generating affordances (a button labeled "Submit" is empty without knowing its mutation contract). Phase 4 distillation reads from both the pins AND this file to populate `screen-spec.md` § Behavior.

`behavior.md` is **input**, not output — `screen-spec.md` § Behavior is the canonical artifact after distillation.

### Phase 2 — Variation exploration with catalog awareness

1. Do an explicit reuse analysis against `registry/manifest.json`. Phrase it like:
   > "Para esta pantalla puedo reutilizar `kpi-card v1` y `data-table-dense v1`. Necesito diseñar nuevo: el header con filtros y el panel lateral. Genero 12 variaciones manteniendo fijos los reutilizados. ¿Confirmas?"

2. **Dispatch the `ui-forge-variator` subagent** to generate `01-variations.html` — do **not** generate the HTML in the main session. Heavy HTML output stays out of the parent context.

   Call shape (via the `Agent` tool, `subagent_type: "ui-forge-variator"`):

   ```
   screen-id: <kebab-case id>
   CWD: <absolute path of the consumer project root>
   N: 12  (or whatever the user chose)
   axis: visual | behavior | data | mixed
   reuse-decision: "<which registry components fixed, which blocks new — from step 1>"
   plugin-root: ${CLAUDE_PLUGIN_ROOT}
   ```

   The subagent reads `brief.md`, `schema.json`, `mock.json`, `behavior.md` (if present), `manifest.json`, `tokens.json` and the `variations.html.tmpl` template, then writes `screens/<id>/01-variations.html` and returns a ≤ 15-line report (per-variant one-line structural summaries + reused components + warnings).

3. Reused components stay fixed across variations; the new bits and the overall composition are what vary. The subagent enforces this — your job in the parent session is to make the reuse decision explicit *before* dispatching.

4. **Variants must be structurally different** — different layout, different information hierarchy, different primary affordance. Different colours or copy alone is not a variant; it's wallpaper. The subagent self-checks for this and redoes wallpaper drafts before writing. See the anti-pattern below.

5. The variations file ships with two browse modes (handled by the template, not your concern in the parent):
   - **Grid scroll** (default) — vertical stack of cards, good for compare-everything.
   - **Focus mode** — full-size single variant with `←` / `→` keyboard navigation and a floating switcher. Toggle via the `Focus mode (F)` button in the sticky nav, or press `F`. `Esc` exits.

6. Show the subagent's report **verbatim** to the user, append the file path, and ask: *"Elige id ganador o `mix: 3+7`"*. Do **not** read `01-variations.html` into your own context — the user opens it in the browser.

### Phase 3 — Annotation (hot-reload loop)

**Trigger:** user names the winning variant ("me gusta la 4", "mix: 3+7").

#### Setup: start the dev server

If the server isn't already running, start it before generating `02-forge.html`. See `references/subcommands.md` for the full command reference.

```
Monitor: bash "${CLAUDE_PLUGIN_ROOT}/skills/ui-forge/scripts/serve.sh"
```

The server prints clickable URLs. Give the user the direct link to their forge page.

#### Generate forge HTML

Generate `02-forge.html` from `templates/forge.html.tmpl`:
- Full-size chosen variation.
- Scenario selector dropdown at the top (switches between `happy`, `empty`, `loading`, `error`, `edge-*` without regenerating HTML).
- `window.UIFORGE_DATA` inlined as `<script id="uiforge-data" type="application/json">` containing every scenario.
- `window.render(data)` defined and must rebuild the DOM for the provided data.
- Overlay script wrapped between `<!-- ui-forge:overlay:start -->` and `<!-- ui-forge:overlay:end -->` — these markers let Phase 4 strip the overlay cleanly.

#### Overlay v2 behavior

When served over http:// (via serve.py), the overlay gains hot-reload features:
- **🚀 Send to Claude** — primary button. POSTs pins to `/forge/feedback`. The server writes `feedback/round-NN.json` + `feedback/latest.json` and prints a trigger line to stdout.
- **SSE auto-reload** — `EventSource('/forge/reload')` detects `02-forge.html` mtime changes and reloads the page automatically.
- Pins are cleared after a successful send so the user starts fresh on the updated page.

Always-available (http:// and file://):
- Click any element while annotating → prompt → pin capturing `{id, selector, x, y, viewport, comment, type, scenario, timestamp}`.
- `type` is one of **7 pin types**, all color-coded:
  - `change` 🔵 — cosmetic / visual / catch-all
  - `extract-as-component` 🟢 — promote this block to the registry as a new component
  - `replace-with-registry` 🟣 — this block should be replaced by an existing registry component
  - `token-issue` 🟠 — wrong token used, missing token, or value inconsistency
  - `data-issue` 🔴 — mock data unrealistic / missing field / missing edge case
  - `logic-rule` ⚙️ — business rule or validation (invariant the UI must respect) · pin colour `#ec4899`
  - `state-transition` 🔄 — temporal/sequential behavior (`X → Y on trigger, after timing`) · pin colour `#06b6d4`
- Panel side-bar, editable comments, per-pin type dropdown.
- 📋 clipboard + ⬇ download as fallback export.
- localStorage persistence.
- Shortcuts: **A** annotate toggle, **P** panel toggle.

#### Hot-reload iteration loop

1. User annotates in the browser → clicks 🚀.
2. Monitor delivers `[ui-forge] round=N screen=<id> new=K total=T | #<id>[type] @(x,y) "comment" || ... | details: show-pin.py <id> --round N` to you.
3. **Dispatch `ui-forge-iterator` automatically** — no confirmation prompt to the user. Call shape (via `Agent` tool, `subagent_type: "ui-forge-iterator"`):

   ```
   screen-id: <parsed from the Monitor line>
   round: <parsed from the Monitor line>
   CWD: <absolute path of the consumer project root>
   plugin-root: ${CLAUDE_PLUGIN_ROOT}
   ```

   The subagent reads `feedback/round-NN.json` + `02-forge.html` + the relevant schema/manifest/tokens files, applies **all pins in the round at once** (a round may carry multiple pins), and writes the updated `02-forge.html`. `serve.py`'s mtime watcher then fires SSE and the browser auto-reloads — no parent-session involvement in the reload.

4. Show the subagent's ≤ 15-line per-pin report verbatim to the user. Do **not** read `02-forge.html` yourself.
5. User sees the change in the browser, annotates again if needed → back to step 1.

No chat paste required. The user never leaves the browser until satisfied. The main session never loads the forge HTML — that's the whole point of the iterator subagent.

If the user explicitly asks to skip the subagent (e.g. *"esta vez aplícalo tú directamente"*), you may fall back to the manual loop: read `latest.json` → read the round → edit `02-forge.html` yourself. This is the exception, not the default.

#### Fallback (file://)

If user opens `02-forge.html` via `file://` (no server), the overlay falls back to v0.1 behavior: 📋 clipboard and ⬇ download only. In this case, use the manual loop: user pastes round JSON into the chat → you regenerate `02-forge.html` → user reloads manually.

### Phase 4 — Distillation

**Trigger:** "aprobado", "destila", "listo".

Phase 4 is split in two: **4a** is human-in-the-loop candidate negotiation, owned by the main session because it requires conversation with the user. **4b** is the mechanical bundle assembly, delegated to the `ui-forge-distiller` subagent so the heavy spec + registry writes don't pollute the parent context.

#### Phase 4a — Candidate identification (main session)

1. Identify component candidates from two signals:
   - **Strong:** pins with `type: extract-as-component` from Phase 3 (look across **all** `feedback/round-*.json`).
   - **Heuristic:** cohesive semantic blocks that repeat or are clearly standalone.

2. Identify fixture and token candidates:
   - **Fixtures:** datasets in `data/mock.json` or scenarios that are clearly reusable (market-indices list, country list, currency list…).
   - **Tokens:** any `token-issue` pin where the iterator left a `warnings:` entry about a missing token.

3. Present everything to the user for confirmation:
   ```
   Componentes nuevos:
     - [pin] header-with-filters → marcado por ti
     - [auto] notification-banner → detectado
   Modificados:
     - kpi-card → cambios en spacing. ¿Promociono a v2?
   Fixtures nuevos detectados:
     - market-indices → 8 índices con valores. ¿Promuevo a registry/fixtures/?
   Tokens propuestos:
     - shadow.elevated (de pin #7 token-issue) → ¿añado a tokens.json?
   ```

4. Collect approvals. Assemble the `approved` payload (each list may be empty `[]`):

   ```
   approved:
     new-components: [{id, source-pin-or-heuristic, sketch}]
     bump-components: [{id, from-version, to-version, why}]
     replace-pins: [{pin-id, registry-id, version}]   ← from Phase 3 replace-with-registry pins, already in HTML
     new-fixtures: [{name, source}]
     new-tokens: [{path, value, why}]
   ```

#### Phase 4b — Bundle assembly (delegate to `ui-forge-distiller`)

5. Dispatch the distiller (`Agent` tool, `subagent_type: "ui-forge-distiller"`) with:

   ```
   screen-id: <kebab-case>
   CWD: <absolute path of the consumer project root>
   plugin-root: ${CLAUDE_PLUGIN_ROOT}
   approved: <the payload from step 4>
   winning-variant: <variant id or "mix: 3+7" from Phase 3>
   ```

6. The distiller does the actual work, all in one pass:
   - Generates `output/screen.html` (strips overlay markers, inlines `mock.json` as the only data source).
   - Generates `output/screen-spec.md` from the template — populates § Behavior from `state-transition` + `logic-rule` pins and `data/behavior.md` (if present), using the heuristic *"`validación:`/`validation:` prefix or named field → § Validations; cross-field invariant → § Business rules"*. Drops empty subsections.
   - Generates `output/decision.md` (skips if Phase 2 produced a single variant).
   - Promotes approved components / bumps versions (never overwrites a prior version), promotes fixtures, adds new tokens.
   - Writes `output/components-used.json` (`{version: 1, screen, registryComponents, newComponents, screenLocal, fixturesUsed}`).
   - Updates `registry/manifest.json` (`usedInScreens`, `currentVersion`, timestamps).
   - Regenerates `registry/catalog.html`.
   - **Runs `scripts/validate-bundle.sh <screen-id>`** and includes the exit code in its report.

7. Show the distiller's structured report to the user. The report ends with `validator: PASS|FAIL`. On **FAIL**, do not declare Phase 5 ready — relay the warnings, and either fix forward or re-dispatch with a corrected `approved` payload (don't hand off a dirty bundle).

### Phase 5 — Handoff

The frontend implementation agent consumes:
- `screens/<id>/output/screen-spec.md` — what to build
- `screens/<id>/output/components-used.json` — what catalog pieces are needed
- `screens/<id>/output/decision.md` — which variant won and why
- `screens/<id>/data/schema.json` — data contract for the screen
- `screens/<id>/data/mock.json` + `scenarios/*.json` — materialized data for happy / empty / loading / error / edge paths
- `registry/components/<id>/<version>/spec.md` — per-component spec
- `registry/tokens.json` — tokens to map to the stack's token system
- `registry/fixtures/*.json` — fixtures for tests/storybook if relevant

For the **full output data model** — exact schemas, relationships between artifacts, invariants Phase 4 guarantees, versioning policy, and what is deliberately not in the bundle — see [`references/output-data-model.md`](references/output-data-model.md). That document is the contract a downstream consumer reads to build the screen without ever touching ui-forge again.

**This skill never writes to `src/` (or any equivalent). Handoff is the boundary.**

## Spec format (component and screen)

```markdown
# <Name>

## Intent
<1-2 sentences>

## Structure
<semantic tree, no class names>

## Design tokens used
- Colors / Spacing / Typography / Radii / Shadows

## States
<only the applicable ones: default/hover/focus/active/disabled/loading/empty/error>

## Interactions
<events and behavior>

## Behavior (screen specs only)
<state transitions · business rules · validations · mutation contracts · conditional rendering. Populated by distilling `state-transition` and `logic-rule` pins plus the optional Phase 1.5 `data/behavior.md`. Drop subsections that don't apply — don't leave empty placeholders.>

## Data contract
<JSON shape + types; reference schema.json or a fixture>

## Accessibility
<ARIA roles, tab order, labels>

## Responsive
<breakpoints and what changes>

## Composition (screen specs only)
<registry components used and how they assemble>

## Out of scope
<what the spec deliberately does not define>
```

Use the templates (`component-spec.md.tmpl`, `screen-spec.md.tmpl`) as scaffolds — fill them, don't rewrite from scratch.

## Anti-patterns — avoid these

- **Don't ship wallpaper variants.** "Three slightly-tweaked card grids isn't a UI prototype, it's wallpaper" (paraphrased from mattpocock/skills · prototype/UI.md). Variants must disagree on structure — different layout, different information hierarchy, or different primary affordance. Different colour, copy, or padding alone is a tweak, not a variant. If two drafts come out too similar, redo one with explicit "do not use a card grid" / "primary affordance must move" guidance.
- **Don't promote everything to a component.** One-off pieces → `screenLocal`. Componentitis is worse than a bit of duplication.
- **Don't bump a version without confirmation.** `v{N+1}` is an explicit decision, always ask.
- **Don't use tokens that aren't in `tokens.json`.** If one is missing, propose adding it first, then use it.
- **Don't touch anything outside `.ui-forge/`.** Ever.
- **Don't hardcode data in HTML.** Data flows through `<script type="application/json">` blocks parameterized by the schema.
- **Don't install dependencies in generated prototypes.** Tailwind via CDN, vanilla JS, nothing else. (Documented exception: the opt-in `pip install aiohttp` that live mode requires — see below.)
- **Don't start generic servers.** The only servers this skill runs are `scripts/serve.sh` via Monitor (hot-reload) and `scripts/live/live.sh` via Monitor (live-mode proxy). Don't start other servers, proxies, or bundlers.
- **Don't generate framework code.** HTML + Tailwind only. Translation to React/Vue/Svelte/etc. is the downstream agent's job.
- **Don't integrate real data or MCPs** in v1. Mock only.
- **Don't mix contradictory fixtures.** If screen A uses `portfolios.diego` with 12 holdings, screen B should use the same subset unless there's an explicit reason to diverge.

## Conventions

- **IDs:** free kebab-case. No forced prefixes.
- **Versioning:** incremental `vN`. No semver.
- **Component identification:** hybrid — manual pins from Phase 3 plus heuristic detection, always confirmed with the user.
- **Persistence:** pure filesystem, everything under `.ui-forge/`, git-versioned.
- **Multi-registry:** N/A. One project, one registry. Sharing between projects is manual `cp -r`.

## Templates available

Located at `${CLAUDE_PLUGIN_ROOT}/skills/ui-forge/templates/`:

| File | Purpose |
|------|---------|
| `variations.html.tmpl` | Phase 2 grid of variants + focus mode (`←` `→` `F` `Esc`) |
| `forge.html.tmpl` | Phase 3 annotated forge HTML shell |
| `component-spec.md.tmpl` | Phase 4 component spec scaffold |
| `screen-spec.md.tmpl` | Phase 4 screen spec scaffold (includes `## Behavior` section) |
| `decision.md.tmpl` | Phase 4 decision record — winning variant, mix sources, rejection rationale |
| `catalog.html.tmpl` | Phase 4 registry gallery |
| `tokens.default.json` | Default Tailwind-ish token set seeded on bootstrap |

## Subagents

The heavy file work in Phases 2/3/4 is delegated to three specialized subagents shipped with this plugin. The main session passes only **screen-id + paths + parameters** — never HTML or large JSON — so the parent context stays clean across long sessions.

| Subagent | Phase | Disparo | Writes |
|---|---|---|---|
| `ui-forge-variator` | 2 | Main session dispatches after locking reuse-vs-new | `screens/<id>/01-variations.html` |
| `ui-forge-iterator` | 3 | Main session dispatches **automatically** on each Monitor `[ui-forge] round=N screen=X ...` line | `screens/<id>/02-forge.html` (one round, possibly several pins, applied as one pass) |
| `ui-forge-distiller` | 4b | Main session dispatches after candidate approval | `output/*`, `registry/*`, runs `validate-bundle.sh` |

Each subagent returns a ≤ 15-line structured report (rutas, per-item summaries, warnings). The main session forwards that report to the user verbatim. **The main session does not read `01-variations.html` or `02-forge.html` directly** — those files are for the browser, not the chat.

Manual fallback: if the user explicitly asks the main session to apply pins itself (rare), it can read `feedback/round-NN.json` + `02-forge.html` and edit directly. Default is always the subagent.

## Assets

- `${CLAUDE_PLUGIN_ROOT}/skills/ui-forge/assets/overlay.js` — the annotation overlay. The bootstrap script copies it to `<project>/.ui-forge/assets/overlay.js` so the HTML files in `screens/` can reference it via a stable relative path.

## Scripts

- `${CLAUDE_PLUGIN_ROOT}/skills/ui-forge/scripts/init-registry.sh` — idempotent bootstrap. Safe to re-run; never overwrites `tokens.json` or any user file that already exists.
- `${CLAUDE_PLUGIN_ROOT}/skills/ui-forge/scripts/serve.sh` — dev server launcher (Phase 3 hot-reload). Thin bash wrapper around `serve.py`; stable path for permission pre-approval. Start via Monitor.
- `${CLAUDE_PLUGIN_ROOT}/skills/ui-forge/scripts/serve.py` — underlying server. Static files + POST `/forge/feedback` (emits full pin content on stdout) + SSE `/forge/reload`. Port 4269. Usually invoked via `serve.sh`, not directly.
- `${CLAUDE_PLUGIN_ROOT}/skills/ui-forge/scripts/stop.sh` — stop the dev server by PID file. Idempotent, cleans stale PID files.
- `${CLAUDE_PLUGIN_ROOT}/skills/ui-forge/scripts/status.sh` — report whether the dev server is running.
- `${CLAUDE_PLUGIN_ROOT}/skills/ui-forge/scripts/refresh-assets.sh` — force-refresh runtime assets (`overlay.js`) in the consumer, without touching config or data.
- `${CLAUDE_PLUGIN_ROOT}/skills/ui-forge/scripts/show-pin.py` — dump full untruncated pin details from a feedback round. Use when the stdout summary from serve.py is truncated or you need a pin from an older round. `--ids`, `--pin N`, `--round N`, `--json` options.

**Pre-approval tip for users:** add `bash **/ui-forge/scripts/*.sh` and `python3 **/ui-forge/scripts/*.py` to `permissions.allow` in `.claude/settings.local.json`. All ui-forge subcommands then run friction-free.

## Subcommands

This skill handles `serve`, `stop`, `status` subcommands for the dev server lifecycle — similar to forge-telegram's start/stop pattern. See `references/subcommands.md` for the full command reference with exact bash snippets, and `references/output-data-model.md` for the canonical schema of the Phase 5 handoff bundle.

| Subcommand | Action |
|------------|--------|
| `serve` | Start dev server under Monitor. Prints clickable URL. |
| `stop` | Kill server by PID from `.ui-forge/.server.pid`. |
| `status` | Check if server is running. |
| `refresh` | Force-copy plugin assets (overlay.js) into `.ui-forge/assets/`, overwriting. Config and data untouched. |
| `live` | Start live overlay proxy in front of an existing dev server. Requires `pip install aiohttp`. |
| `stop-live` | Kill live proxy by PID from `.ui-forge/.live-server.pid`. |
| `status-live` | Check if live proxy is running. |

<!-- ui-forge:live:start -->

## Live mode — overlay over an existing dev server

Use when you want to annotate the **real running application** (any stack: Vite, Next, Rails, Django, Phoenix, ...) the same way you annotate prototypes — without modifying the app's source. The live proxy sits in front of your dev server, injects `overlay.js` into HTML responses, and collects pins in `.ui-forge/live/<session-id>/`. Closing the proxy removes the overlay end-to-end — no code change in the consumer app, nothing to leak to deployment.

**Requires `aiohttp`** — opt-in, install once with `pip install aiohttp`. Prototype mode keeps working without it.

**What this is NOT (v1):** Claude does **not** auto-edit `src/` from live-mode pins. Pins land as JSON; you decide when and how to apply them. (Auto-apply is a v2 follow-up.)

Exact flags, startup line, feedback-event format, limitations, and stop/status commands: see `references/subcommands.md` § live / stop-live / status-live.

<!-- ui-forge:live:end -->

## Quick checklist when the skill activates

1. Is `.ui-forge/` present? If not, run `init-registry.sh`.
2. Read `registry/manifest.json`, `registry/tokens.json`, `registry/fixtures/index.json`.
3. Freeze the brief at `screens/<id>/brief.md`.
4. Generate schema + scenarios with domain-plausible data.
5. **Stateful screen?** (wizard, state machine, mutation-heavy, complex validations) → also generate `data/behavior.md` skeleton (Phase 1.5). Read-only displays skip this.
6. Propose reuse vs. new design explicitly against the manifest. Lock the decision before dispatching to Phase 2.
7. **Phase 2** — dispatch `ui-forge-variator` to write `01-variations.html`. Show the agent's report verbatim; user opens the file in the browser, chooses winner (grid scroll or focus mode with `←` `→`) → forge.
8. **Phase 3** — on every Monitor `[ui-forge] round=N screen=X ...` line, auto-dispatch `ui-forge-iterator`. Multiple pins per round are normal; the subagent applies them all in one pass. Browser auto-reloads via SSE. New pin types: `logic-rule` for business rules / validations; `state-transition` for temporal behaviors.
9. **Phase 4** — on "approved": negotiate component / fixture / token candidates with the user (4a), then dispatch `ui-forge-distiller` with the approved payload (4b). The distiller runs `validate-bundle.sh` itself; only declare Phase 5 ready on `validator: PASS`.
10. Hand off the spec package. Stop before `src/`.
