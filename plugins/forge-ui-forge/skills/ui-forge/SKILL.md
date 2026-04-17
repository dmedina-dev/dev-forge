---
name: ui-forge
description: Prototype full UI screens iteratively before implementing them in production code while maintaining a per-project growing catalog of reusable components and shared data fixtures. Includes hot-reload dev server with SSE — user annotates in the browser, clicks 🚀 Send to Claude, Claude regenerates HTML, browser reloads automatically. Subcommands for the dev server lifecycle: "ui-forge serve" (start), "ui-forge stop", "ui-forge status". Triggers when the user wants to design a new screen, explore visual variations, gather inline feedback via click-to-annotate, or build up a reusable component library through prototyping. Also triggers on Spanish phrases like "prototipar la pantalla de", "diseña la UI de", "explora opciones visuales para", "quiero mockear", "necesito maquetar", "arranca ui-forge", "para el servidor". Five-phase flow: bootstrap `.ui-forge/`, generate mock data and scenarios from a declarative schema with optional fixture reuse, generate N HTML screen variations reusing registry components when applicable, iterate on chosen variation with hot-reload annotation overlay — user clicks 🚀 to send pins, Claude regenerates, browser auto-reloads via SSE, distill into clean `screen.html` plus framework-agnostic `screen-spec.md`, then promote selected blocks to versioned components and reusable datasets to shared fixtures. All artifacts live under `.ui-forge/` in the project root, git-versioned. Never modifies the consumer project's source tree, never installs dependencies, never generates framework-specific code, never hardcodes mock data inline. Use this skill whenever the user mentions prototyping screens, UI variations, mockups, wireframes, design exploration, iterating on visual interfaces before writing production code, starting/stopping the ui-forge server, or sending feedback from the overlay. Do NOT use for bug fixes in existing UI, small CSS tweaks, or when an approved external design (Figma, Sketch) is already ready for direct implementation.
version: 0.2.0
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
    └── output/{screen.html, screen-spec.md, components-used.json}
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

### Phase 2 — Variation exploration with catalog awareness

1. Do an explicit reuse analysis against `registry/manifest.json`. Phrase it like:
   > "Para esta pantalla puedo reutilizar `kpi-card v1` y `data-table-dense v1`. Necesito diseñar nuevo: el header con filtros y el panel lateral. Genero 12 variaciones manteniendo fijos los reutilizados. ¿Confirmas?"

2. Generate `01-variations.html` using `templates/variations.html.tmpl`. Default N=12 (confirm with user if they prefer more/less). All variants share the same `mock.json`, same viewport dimensions, same tokens. Each card has `data-variant-id`.

3. Reused components stay fixed across variations; the new bits and the overall composition are what vary.

4. Output the file path and tell the user: *"Elige id ganador o `mix: 3+7`"*.

### Phase 3 — Annotation (hot-reload loop)

**Trigger:** user names the winning variant ("me gusta la 4", "mix: 3+7").

#### Setup: start the dev server

If the server isn't already running, start it before generating `02-forge.html`. See `references/subcommands.md` for the full command reference.

```
Monitor: python3 "${CLAUDE_PLUGIN_ROOT}/skills/ui-forge/scripts/serve.py"
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
- `type` ∈ `{change, extract-as-component, replace-with-registry, token-issue, data-issue}` — color-coded pins.
- Panel side-bar, editable comments, per-pin type dropdown.
- 📋 clipboard + ⬇ download as fallback export.
- localStorage persistence.
- Shortcuts: **A** annotate toggle, **P** panel toggle.

#### Hot-reload iteration loop

1. User annotates in the browser → clicks 🚀.
2. Monitor delivers `[ui-forge] feedback screen=<id> round=<n> pins=<k>` to you.
3. Read `.ui-forge/screens/<id>/feedback/latest.json` → get the round filename.
4. Read the full round file → apply the changes to `02-forge.html`.
5. Write the updated file → serve.py detects mtime change → SSE → browser reloads.
6. User sees the result, annotates again if needed. Repeat.

No chat paste required. The user never leaves the browser until satisfied.

#### Fallback (file://)

If user opens `02-forge.html` via `file://` (no server), the overlay falls back to v0.1 behavior: 📋 clipboard and ⬇ download only. In this case, use the manual loop: user pastes round JSON into the chat → you regenerate `02-forge.html` → user reloads manually.

### Phase 4 — Distillation

**Trigger:** "aprobado", "destila", "listo".

1. Generate `output/screen.html` — **strip everything between the overlay markers**, inline `mock.json` as the only data source, self-contained.

2. Generate `output/screen-spec.md` from `templates/screen-spec.md.tmpl` (see spec format below).

3. Identify component candidates from two signals:
   - **Strong:** pins with `type: extract-as-component` from Phase 3.
   - **Heuristic:** cohesive semantic blocks that repeat or are clearly standalone.

4. Present candidates to the user for confirmation:
   ```
   Componentes nuevos:
     - [pin] header-with-filters → marcado por ti
     - [auto] notification-banner → detectado
   Modificados:
     - kpi-card → cambios en spacing. ¿Promociono a v2?
   Fixtures nuevos detectados:
     - market-indices → 8 índices con valores. ¿Promuevo a registry/fixtures/?
   ```

5. For each approved candidate:
   - New component → `registry/components/<id>/v1/{component.html, spec.md}`.
   - Modified component → `registry/components/<id>/v{N+1}/` — **never overwrite** a prior version.
   - New fixture → `registry/fixtures/<name>.json` + update `fixtures/index.json`.
   - Update `registry/manifest.json` (`usedInScreens`, `currentVersion`, timestamps).

6. Write `output/components-used.json`:
   ```json
   {
     "screen": "portfolio-overview",
     "registryComponents": [{"id": "kpi-card", "version": "v2"}, {"id": "data-table-dense", "version": "v1"}],
     "newComponents": ["header-with-filters", "notification-banner"],
     "screenLocal": ["empty-state-illustration"],
     "fixturesUsed": ["portfolios"]
   }
   ```

7. Regenerate `registry/catalog.html` from `templates/catalog.html.tmpl`.

### Phase 5 — Handoff

The frontend implementation agent consumes:
- `screens/<id>/output/screen-spec.md` — what to build
- `screens/<id>/output/components-used.json` — what catalog pieces are needed
- `screens/<id>/data/schema.json` — data contract for the screen
- `registry/components/<id>/<version>/spec.md` — per-component spec
- `registry/tokens.json` — tokens to map to the stack's token system
- `registry/fixtures/*.json` — fixtures for tests/storybook if relevant

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

- **Don't promote everything to a component.** One-off pieces → `screenLocal`. Componentitis is worse than a bit of duplication.
- **Don't bump a version without confirmation.** `v{N+1}` is an explicit decision, always ask.
- **Don't use tokens that aren't in `tokens.json`.** If one is missing, propose adding it first, then use it.
- **Don't touch anything outside `.ui-forge/`.** Ever.
- **Don't hardcode data in HTML.** Data flows through `<script type="application/json">` blocks parameterized by the schema.
- **Don't install dependencies.** Tailwind via CDN, vanilla JS, nothing else.
- **Don't start generic servers.** The only server this skill runs is `scripts/serve.py` via Monitor (for hot-reload). Don't start other servers, proxies, or bundlers.
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
| `variations.html.tmpl` | Phase 2 grid of variants |
| `forge.html.tmpl` | Phase 3 annotated forge HTML shell |
| `component-spec.md.tmpl` | Phase 4 component spec scaffold |
| `screen-spec.md.tmpl` | Phase 4 screen spec scaffold |
| `catalog.html.tmpl` | Phase 4 registry gallery |
| `tokens.default.json` | Default Tailwind-ish token set seeded on bootstrap |

## Assets

- `${CLAUDE_PLUGIN_ROOT}/skills/ui-forge/assets/overlay.js` — the annotation overlay. The bootstrap script copies it to `<project>/.ui-forge/assets/overlay.js` so the HTML files in `screens/` can reference it via a stable relative path.

## Scripts

- `${CLAUDE_PLUGIN_ROOT}/skills/ui-forge/scripts/init-registry.sh` — idempotent bootstrap. Safe to re-run; never overwrites `tokens.json` or any user file that already exists.
- `${CLAUDE_PLUGIN_ROOT}/skills/ui-forge/scripts/serve.py` — dev server for hot-reload (Phase 3). Static files + POST `/forge/feedback` + SSE `/forge/reload`. Port 4269. Start via Monitor.

## Subcommands

This skill handles `serve`, `stop`, `status` subcommands for the dev server lifecycle — similar to forge-telegram's start/stop pattern. See `references/subcommands.md` for the full command reference with exact bash snippets.

| Subcommand | Action |
|------------|--------|
| `serve` | Start dev server under Monitor. Prints clickable URL. |
| `stop` | Kill server by PID from `.ui-forge/.server.pid`. |
| `status` | Check if server is running. |

## Quick checklist when the skill activates

1. Is `.ui-forge/` present? If not, run `init-registry.sh`.
2. Read `registry/manifest.json`, `registry/tokens.json`, `registry/fixtures/index.json`.
3. Freeze the brief at `screens/<id>/brief.md`.
4. Generate schema + scenarios with domain-plausible data.
5. Propose reuse vs. new design explicitly against the manifest.
6. Generate variations → user chooses → forge.
7. Iterate via round-NN JSON paste loop.
8. On "approved": distill, promote components/fixtures with confirmation, regenerate catalog.
9. Hand off the spec package. Stop before `src/`.
