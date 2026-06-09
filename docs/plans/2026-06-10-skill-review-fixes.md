# Plan: aplicar hallazgos de la revisión de skills (2026-06-09)

Fuente: revisión multi-agente de las 39 skills (informe completo en `.tmp/skill-review-2026-06-09.md`,
86 hallazgos confirmados tras verificación adversarial). Rama de trabajo: `fable-cuarte`.

Ya aplicado antes de este plan: corrección forge-profiles (enabledPlugins/.mcp.json),
eliminación de forge-context-mcp (17 plugins), descripción de ui-forge ≤1024 chars.

## Wave 1 — Nativos rápidos (sin overhead vendor)

Cada ítem: editar → `claude --plugin-dir plugins/<name>` smoke test.

- [x] **forge-brainstorming**: reemplazar 10 referencias `superpowers:` → `forge-superpowers:`
      (SKILL.md:53,86-92; commands/brainstorming.md:65,92; references/phase-orchestration*).
- [x] **forge-telegram**: prefijar `${CLAUDE_PLUGIN_ROOT}/` en SKILL.md:90,144 y
      references/subcommands.md:70,108,216; renumerar flujo inbound (0,1,2,3,2.5,3.5,4,5 → secuencial)
      actualizando las referencias cruzadas (SKILL.md:56,146).
- [x] **forge-keeper**: SKILL.md:6-8,18 — corregir claim "before /clear" → PreCompact solo para
      /compact; /clear se rescata vía SessionStart post-clear.
- [x] **forge-ui-forge** (restantes): SKILL.md:207 `serve.py` → `serve.sh`; scoping de anti-patterns
      (398-399) para no contradecir live mode (476); frase forge-logic-prototype (150-151) como
      hipotética; subcommands.md:37 formato stdout real (`round=<n> screen=<id> new=<k> total=<t>`);
      condensar sección Live mode (470-524) a puntero → references/subcommands.md.
- [x] **forge-export**: install-all generado a ruta no descubrible (SKILL.md:94-95 +
      output-schema.md:377) → bootstrap-plugin o `.claude/commands/`; Quick start inválido
      (output-schema.md:518-526) → `/plugin marketplace add` + install; refrescar ejemplos stale de
      interview-guide.md (v5.0.6/19 → placeholders).
- [x] **forge-init**: mensaje cleanup condicional sobre forge-keeper (SKILL.md:71); alinear
      descripción/body sobre install-all (SKILL.md:9-10).

## Wave 2 — Paridad de docs del repo (sin tocar plugins)

- [x] README.md:65 + dependencies.md:49: `/hookify-list|configure|help` → `/forge-hookify:list|configure|help`.
- [x] README.md:63 + dependencies.md:62: `/clean-gone` → `/forge-commit:clean_gone`.
- [x] README.md:41-47: añadir `/handoff` y `/heal-plugin-cache` a forge-keeper.
- [x] README.md:80: `/proactive-qa:init` → `/forge-proactive-qa:init`.
- [x] CLAUDE.md:68: aclarar que forge-proactive-qa es nativo pero mantiene customizations.json con
      `origin.type: "native"` como changelog de genericización; documentar la variante `native` en
      docs/customizations-pattern.md.
- [x] docs/dependencies.md: notas de arbitraje de triggers — diagnose vs systematic-debugging,
      tdd vs test-driven-development, to-prd vs writing-plans (texto propuesto en el informe).

## Wave 3 — Vendored con entrada en customizations.json (lote por plugin, 1 entrada cubre el lote)

- [x] **forge-hookify**: reescribir sección stop-events (SKILL.md:182-201) a forma conditions
      (`field: transcript|reason`); añadir `Stop: reason, transcript` al Quick Reference (368-371);
      listar `require-tests-stop.local.md` en ejemplos (324-327). 1 entrada `modified`.
- [x] **forge-proactive-qa**: rutas references/ → `${CLAUDE_PLUGIN_ROOT}/references/...`
      (SKILL.md:246,248,258); estado cycle (212 vs 233); screenshots contradicción (99 vs 111);
      "Both modes" → "All modes" (20); nota sandbox $TMPDIR + operational.md § sandbox.
- [x] **forge-plugin-dev**: quitar test-agent-trigger.sh (agent-dev:399); model/color → opcionales
      (115,127, tabla, validate-agent.sh); rutas validate-agent.sh con ${CLAUDE_PLUGIN_ROOT};
      eliminar sintaxis $IF() (command-dev:392-396 + features-ref:453,496); sección AskUserQuestion
      → puntero a interactive-commands.md + enumerar 7 references; wrapper "hooks" en
      plugin-structure:216-227 y hook-dev:344-381; security-guidance → forge-security (hook-dev:694);
      `cc` → `claude` (skill-dev:288); contradicción restart en plugin-settings (369,383 vs 200,450);
      ejemplo agent `capabilities` → schema real (plugin-structure:151-158); quitar `name:` de ejemplo
      command (125-129). Entradas `modified` por archivo.
- [x] **forge-superpowers**: cross-refs `superpowers:` → `forge-superpowers:` (19 occurrencias,
      4 archivos) + entrada que complete custom-25; visual-companion.md rutas con
      ${CLAUDE_PLUGIN_ROOT} (7 invocaciones); atribución brainstorming v5.0.7 → v5.1.0 + formato
      estándar; finishing-a-development-branch: capturar GIT_DIR/WORKTREE_PATH antes del cd (101-102
      vs 176-181); requesting-code-review: añadir el WHAT a la descripción; eliminar huérfanos
      plan-document-reviewer-prompt.md y spec-document-reviewer-prompt.md (entradas `removed`);
      excluir CREATION-LOG.md + test-pressure-* en próximo sync (entrada `excluded`).
- [x] **forge-frontend-design**: `license:` → `Apache-2.0` + comentario de atribución que
      custom-01 ya afirma existir.
- [x] **forge-mattpocock** (higiene customizations.json, casi todo metadata local): entrada
      `modified` para ADR-FORMAT.md; entrada `added` para GLOSSARY-FORMAT.md (riesgo rsync --delete);
      normalizar paths custom-06/custom-24; propagar custom-24 a HTML-REPORT.md:3; README pin
      b56795b → b8be62f; README claim "commit per cycle" del tdd.

## Wave 4 — Backfill de atribución (mecánico)

- [x] Insertar `<!-- Curated from <repo>/<path> · <license>. Unmodified|Adapted: … -->` tras el
      frontmatter en los 21 SKILL.md vendored sin comentario (superpowers ×13, plugin-dev ×7,
      hookify ×1 — frontend-design cae en Wave 3). Origen ya está en cada customizations.json.
      Una entrada `modified` por plugin (o ampliar la existente).

## Wave 5 — Release

- [x] `bash scripts/marketplace-health.sh` + smoke tests de los plugins tocados.
- [x] `/release` → **v3.0.0** (breaking: eliminación de forge-context-mcp) + CHANGELOG.md
      (regla: todo release actualiza CHANGELOG) + refresco de pins en README si aplica.

## Diferidos (decisión consciente, no olvido)

- Adelgazar cuerpos de forge-plugin-dev (command-dev 835 líneas, skill-dev 638, hook-dev 713,
  mcp-int 555, settings 545) — solo en el próximo upstream sync, no como edición standalone.
- Lows de prosa vendored sin lote que los arrastre (caveman /caveman, diagnose handoff namespace,
  executing-plans "review checkpoints", subagent-driven "parallel-safe").
- **forge-memory**: nuevo plugin que reformula el espacio de forge-context-mcp (idea de dmedina,
  diseño pendiente — no es un fix, es un plugin nuevo).
