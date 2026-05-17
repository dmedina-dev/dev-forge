# Output data model — what Phase 5 hands off

This document is the contract between **ui-forge** (the prototyping skill) and **anything downstream** that consumes its output: a frontend-implementation agent, a code generator, a designer reviewing the spec, a Storybook author wiring fixtures, or a human reading "what does this prototype say I should build?".

ui-forge runs five phases under `<project>/.ui-forge/` and stops at the boundary — **it never writes into `src/`**. Phase 5 is the handoff: a frozen, self-contained bundle that captures three independent axes — **visual**, **behavior**, **data** — plus the workflow trail that produced them. A downstream consumer should be able to pick up this bundle and build the screen without ever talking to ui-forge again.

## TL;DR for downstream consumers

> Read these files, in this order, to understand what to build:
>
> 1. `screens/<screen-id>/brief.md` — why and what (one-paragraph problem statement).
> 2. `screens/<screen-id>/output/decision.md` — which of the explored variants won and why.
> 3. `screens/<screen-id>/output/screen-spec.md` — the canonical spec: structure, tokens, states, interactions, **behavior** (state machine + business rules + validations + mutations + conditional rendering), data contract, accessibility, responsive, composition, out-of-scope.
> 4. `screens/<screen-id>/output/components-used.json` — manifest of which catalog components, which new ones, which screen-local.
> 5. `screens/<screen-id>/data/schema.json` — declarative data contract.
> 6. `screens/<screen-id>/data/mock.json` + `scenarios/*.json` — concrete data for happy / empty / loading / error / edge-* paths.
> 7. `registry/tokens.json` — design tokens to map to your stack's token system.
> 8. `registry/components/<id>/<version>/spec.md` — per-component specs for everything in `components-used.json.registryComponents`.
> 9. `registry/fixtures/<name>.json` — shared fixtures referenced from `schema.json`.
>
> Files outside this list (e.g. `feedback/round-NN.json`, `01-variations.html`, `02-forge.html`) are **process artifacts**, not output. They're kept for audit and resumption — not consumed by the downstream build.

## Bundle map

```
<project>/.ui-forge/
├── config.json                          # workspace config
├── assets/overlay.js                    # process — annotation runtime
├── registry/                            # shared, cross-screen
│   ├── manifest.json                    #   component catalog
│   ├── tokens.json                      #   design tokens (visual axis)
│   ├── catalog.html                     #   gallery view
│   ├── fixtures/
│   │   ├── index.json                   #   fixture registry
│   │   └── <name>.json                  #   reusable datasets
│   └── components/<id>/v<N>/
│       ├── component.html               #   versioned component markup
│       └── spec.md                      #   versioned component spec
└── screens/<screen-id>/
    ├── brief.md                         # input — frozen brief
    ├── data/
    │   ├── schema.json                  # data axis — declarative contract
    │   ├── mock.json                    # data axis — happy scenario
    │   ├── scenarios/
    │   │   ├── empty.json
    │   │   ├── loading.json
    │   │   ├── error.json
    │   │   ├── happy.json
    │   │   └── edge-*.json
    │   └── behavior.md                  # behavior axis — optional skeleton (Phase 1.5)
    ├── 01-variations.html               # process — Phase 2 grid
    ├── 02-forge.html                    # process — Phase 3 working file
    ├── feedback/                        # process — pin history (audit trail)
    │   ├── latest.json
    │   └── round-NN.json
    └── output/                          # ← OUTPUT (canonical handoff)
        ├── screen.html                  # final clean HTML, no overlay
        ├── screen-spec.md               # canonical spec
        ├── decision.md                  # variant rationale
        └── components-used.json         # composition manifest
```

## The three axes, made explicit

ui-forge organizes everything it produces along three independent axes. A downstream consumer can pick any axis and ignore the others without losing internal consistency.

| Axis | Source files | Captures | Lifecycle |
|---|---|---|---|
| **Visual** | `registry/tokens.json`, `output/screen.html`, `registry/components/<id>/<version>/component.html` | color, type, spacing, radii, shadows, layout grid, breakpoints, component markup | tokens evolve explicitly; component versions are append-only (`v1` → `v2`, never overwrite) |
| **Behavior** | `output/screen-spec.md` § Behavior, `data/behavior.md` (input) | state transitions, business rules, validations, mutation contracts, conditional rendering | distilled per screen from `state-transition` + `logic-rule` pins plus the Phase 1.5 skeleton |
| **Data** | `data/schema.json`, `data/mock.json`, `data/scenarios/*.json`, `registry/fixtures/*.json` | entity shapes, types, ranges, enums, counts, scenario set, cross-screen reusable datasets | schema is declarative; fixtures are append-only; scenarios always include `happy/empty/loading/error` at minimum |

A "screen" is what you get when you bind one set of components (visual) and one set of mutations + states (behavior) to one schema (data) under a frozen brief.

## File schemas

### `config.json`

```json
{
  "version": 1,
  "naming": "kebab-case"
}
```

Workspace-level config. `version` is the on-disk schema version; bump if any other file's shape changes in a breaking way. `naming` enforces id conventions (kebab-case is currently the only supported value).

### `screens/<screen-id>/brief.md`

Free-form markdown. Frozen at the end of Phase 0. Convention:

```markdown
# <Screen title>

## Problem
<one paragraph: who, what pain, why now>

## Users
<who sees this screen and what they're trying to do>

## Out of scope
<deliberate omissions — referenced by Rule 7 of the precedence charter>
```

The brief is **input** to all subsequent phases; it is reproduced in the output bundle so downstream consumers don't need to read the process artifacts to learn the "why".

### `screens/<screen-id>/data/schema.json`

```json
{
  "entities": {
    "<entity-name>": {
      "import": "registry/fixtures/<name>.json",  // OR
      "select": "<key>",                          //   together pick a slice
      "shape": {                                  // OR inline shape
        "<field>": "uuid"                              // primitive type
                 | { "type": "string|number|date|boolean", "range": [min, max] }
                 | { "enum": [...] }
                 | { "ref": "<other-entity>" }
      },
      "count": {
        "default": <n>,
        "empty": 0,
        "edge-<name>": <n>
      }
    }
  }
}
```

Declarative — no executable code. `import` + `select` reference a registry fixture; otherwise an inline `shape` + `count` spec materializes the entity. `count.empty` and `count.edge-*` map to scenario files of the same name.

### `screens/<screen-id>/data/mock.json` + `scenarios/*.json`

Concrete instances. `mock.json` is the materialized **happy** scenario. The `scenarios/` directory has one JSON per scenario name; each has the same top-level shape as `mock.json` (one key per entity) but with data tuned to that path:

| Scenario | Convention |
|---|---|
| `happy.json` | duplicate of `mock.json` — kept for parity with other scenarios |
| `empty.json` | all entities materialized with `count.empty` (typically 0 / null / `[]`) |
| `loading.json` | sentinel values that mean "still fetching" — usually `null` or a `__loading: true` marker per entity |
| `error.json` | each entity replaced by `{ __error: "<message>" }` — UI renders the error state |
| `edge-<name>.json` | declared explicitly; materialized with `count.edge-<name>` |

`window.UIFORGE_DATA` in `02-forge.html` inlines **every** scenario; `output/screen.html` inlines **only** `mock.json` (downstream consumers wire their own data layer).

### `screens/<screen-id>/data/behavior.md` (optional)

Generated only when Phase 1.5 activates. Input artifact, not output — its content is distilled into `output/screen-spec.md` § Behavior in Phase 4.

```markdown
# <Screen> · behavior

## State transitions
<from → to (on <trigger>, after <timing>)>

## Business rules
<invariants the UI must respect — cross-field, domain-level>

## Validations
<per-field constraints: required, ranges, format>

## Mutation contracts
### <action-name>
- preconditions: ...
- effects: ...
- success: ...
- error: ...

## Conditional rendering
<rules beyond static scenarios: "if N > 100 → render pagination">
```

### `screens/<screen-id>/output/screen-spec.md` (canonical)

The contract document. Sections:

```markdown
# <Screen>

## Intent             — 1-2 sentences
## Structure          — semantic tree, no class names
## Design tokens used — Colors / Spacing / Typography / Radii / Shadows
## States             — only applicable: default/hover/focus/active/disabled/loading/empty/error
## Interactions       — events and behavior
## Behavior           — state transitions · business rules · validations · mutation contracts · conditional rendering
## Data contract      — JSON shape + types; reference schema.json or a fixture
## Accessibility      — ARIA roles, tab order, labels
## Responsive         — breakpoints and what changes
## Composition        — registry components used and how they assemble
## Out of scope       — what the spec deliberately does not define
```

Empty subsections are **dropped**, not left as placeholders. The downstream consumer can rely on "if a section is present, it has content".

### `screens/<screen-id>/output/decision.md`

```markdown
# <Screen> · decision

## Winning variant
<id> — <one-paragraph rationale>

## Mixed in (optional)
- from <variant-id>: <what>
- from <variant-id>: <what>

## Discarded
- <variant-id>: <one-line rejection reason>
```

Captures the **reasoning**, not just the result. Future readers asking "why does this screen look like this?" find the answer here. Skipped only when Phase 2 generated a single variant.

### `screens/<screen-id>/output/components-used.json`

```json
{
  "screen": "<screen-id>",
  "registryComponents": [
    { "id": "<component-id>", "version": "v<N>" }
  ],
  "newComponents": ["<component-id>", ...],
  "screenLocal": ["<block-name>", ...],
  "fixturesUsed": ["<fixture-name>", ...]
}
```

Composition manifest. The downstream consumer reads `registryComponents` and `newComponents` to know which `registry/components/<id>/<version>/spec.md` files to consult, and `fixturesUsed` to know which `registry/fixtures/*.json` are in play.

`screenLocal` lists blocks that exist only inside `output/screen.html` and were deliberately **not** promoted to the registry — one-offs that don't earn componentization.

### `screens/<screen-id>/output/screen.html`

Self-contained HTML. Phase 4 strips:
- Everything between `<!-- ui-forge:overlay:start -->` and `<!-- ui-forge:overlay:end -->`.
- The scenario selector and `window.UIFORGE_DATA` block (replaced by inlined `mock.json` only).
- Any `data-uiforge-*` attributes added by the overlay for picking.

What remains: production-shape HTML + Tailwind CDN + the `window.render(data)` function bound to the inlined happy scenario. A downstream consumer can open this file directly and see the final visual.

### `registry/manifest.json`

```json
{
  "version": 1,
  "components": [
    {
      "id": "<component-id>",
      "currentVersion": "v<N>",
      "versions": ["v1", "v2", ...],
      "usedInScreens": ["<screen-id>", ...],
      "createdAt": "<ISO8601>",
      "lastUpdatedAt": "<ISO8601>",
      "tags": ["optional", "..."]
    }
  ]
}
```

The catalog. Append-only on `versions`. `currentVersion` is the default version downstream consumers should bind to when not otherwise specified.

### `registry/tokens.json`

```json
{
  "version": 1,
  "color": { "<token>": "<value>", ... },
  "spacing": { "<token>": "<value>", ... },
  "typography": { "<token>": { "family": "...", "size": "...", "weight": "...", "lineHeight": "..." }, ... },
  "radii": { "<token>": "<value>", ... },
  "shadow": { "<token>": "<value>", ... },
  "breakpoint": { "<token>": "<value>", ... }
}
```

Token namespaces are open — projects may add custom buckets (`motion`, `z-index`, ...) — but the listed ones are the conventional baseline seeded by `templates/tokens.default.json`. Values are strings; downstream consumers map them to their stack's token format (Tailwind config, CSS custom properties, Style Dictionary, etc.).

### `registry/components/<id>/v<N>/component.html`

Standalone HTML fragment that renders the component in isolation. Same Tailwind CDN as the screen files. No external dependencies. Inlined sample data near the top of the file (so the component renders when opened directly).

### `registry/components/<id>/v<N>/spec.md`

Same section schema as `screen-spec.md` minus § Behavior and § Composition (components don't compose other components in ui-forge — that's the screen's job). Adds an explicit § Data contract at the component level.

### `registry/fixtures/<name>.json`

```json
{
  "<key-or-id>": { /* one record */ },
  ...
}
```

Or:

```json
[
  { /* records */ },
  ...
]
```

Free-form structurally — the consumer expects the shape declared in `registry/fixtures/index.json`.

### `registry/fixtures/index.json`

```json
{
  "<fixture-name>": {
    "shape": "<one-paragraph description>",
    "select": "<key|index|none>",
    "usedInScreens": ["<screen-id>", ...],
    "createdAt": "<ISO8601>"
  }
}
```

Fixture registry. `select` indicates how `schema.json#entities.*.select` resolves into the file (key lookup, array index, or "use the whole file").

### `registry/catalog.html`

Browsable gallery — Phase 4 regenerates this from `manifest.json`. Not an input to downstream consumers; useful for humans skimming the catalog.

## Relationships and references

```
brief.md ────────────────────► screen-spec.md § Intent / § Out of scope
behavior.md ─────────────────► screen-spec.md § Behavior  (distillation)
schema.json ─────────────────► screen-spec.md § Data contract  (reference, not duplication)
schema.json#import ──────────► registry/fixtures/<name>.json
manifest.json#components[*] ─► registry/components/<id>/v<N>/{component.html, spec.md}
components-used.json ────────► subset of manifest.json plus screen-local blocks
mock.json / scenarios/*.json ─ materialized instances of schema.json#entities
output/screen.html ──────────► binds tokens.json + components from manifest.json + mock.json
decision.md ─────────────────► references variant ids from 01-variations.html (process artifact)
```

**Single source of truth per fact:**

- Design tokens: `tokens.json`. The spec references token names, never values.
- Data shapes: `schema.json`. The spec describes the contract; the data files materialize it.
- Component markup: `registry/components/<id>/v<N>/component.html`. The screen embeds composed instances; the registry holds the canonical.
- Behavior: `screen-spec.md § Behavior` (after distillation). `behavior.md` is the working notebook and may go stale.

## Invariants

The handoff bundle satisfies these invariants. If a downstream consumer detects a violation, it's a Phase 4 bug, not a downstream concern:

1. **Every field in `output/screen.html` exists in `schema.json`.** Rule 3 of the precedence charter; verified by Phase 4 schema-conformance check.
2. **Every token used in `output/screen.html` or any `component.html` exists in `tokens.json`.** Rule 5.
3. **Every component listed in `components-used.json.registryComponents` exists in `manifest.json` at the declared version.** Phase 4 cross-reference.
4. **Every fixture in `components-used.json.fixturesUsed` exists in `fixtures/index.json` and on disk.** Phase 4 cross-reference.
5. **`output/screen.html` contains no `<!-- ui-forge:* -->` markers and no `data-uiforge-*` attributes.** Strip is complete.
6. **`screen-spec.md § Behavior` is non-empty if and only if the screen has at least one state transition, validation, business rule, mutation contract, or conditional rendering rule.** Otherwise the section is dropped (no empty placeholders).
7. **Component versions are append-only.** A `v2` exists alongside `v1`; `v1` is never edited in place. Downstream consumers can pin to a version and trust it.

## Lifecycle and versioning

- **Schema versions** (`version: 1` in `config.json` / `manifest.json` / `tokens.json`): bump on breaking shape changes. The skill announces the bump and provides a migration note.
- **Component versions** (`v1`, `v2`, ...): bumped explicitly per Rule 1 of the precedence charter ("don't bump a version without confirmation"). The `usedInScreens` array on the manifest entry shows which screens reference which version — downstream consumers can stay on an older version safely.
- **Fixture versions**: not versioned in v1. Fixtures evolve in place. If you need a frozen snapshot, copy the file and reference the new path explicitly.
- **Screen revisions**: ui-forge doesn't version screens. A second pass at the same screen creates a new screen-id (e.g. `portfolio-overview` → `portfolio-overview-v2`), keeping the old bundle intact for diffing.

## What is deliberately NOT in the bundle

Anti-features — listed so downstream consumers don't go looking:

- **No framework code.** No React, Vue, Svelte, or component-library bindings. The translation from spec + tokens + HTML to your stack is the downstream agent's job.
- **No live data integration.** No API client code, no MCP wiring, no real backend. All scenarios are mock.
- **No build configuration.** No `package.json`, no bundler config, no Storybook setup. The bundle is files; you decide the build.
- **No CSS preprocessor.** Tailwind via CDN is the only styling layer. Tokens map to your stack at integration time, not before.
- **No tests.** Unit / visual / integration tests live in the consumer project; the spec is what they test against, not a thing they're shipped with.
- **No deploy targets.** Storybook entries, Figma exports, screenshot bots — all out of scope for ui-forge v1.

If a downstream consumer wants any of the above, it generates them **from** the bundle, not **inside** it.

## Process artifacts (not part of the handoff)

These files exist under `.ui-forge/` for resumption and audit but are not consumed downstream. Listed here so you know to ignore them when building from the bundle:

- `screens/<id>/01-variations.html` — Phase 2 exploration grid.
- `screens/<id>/02-forge.html` — Phase 3 working file (overlay-instrumented).
- `screens/<id>/feedback/round-NN.json` + `latest.json` — pin history.
- `assets/overlay.js` — annotation runtime, copied per project for `file://` fallback.

`02-forge.html` and `01-variations.html` are useful as *historical reference* if a future reader asks "what alternatives were considered?" — but `decision.md` is the canonical answer to that question.
