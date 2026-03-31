---
paths:
  - .claude/plugins/*/forge-proactive-qa/**
---

# Proactive QA — Reglas obligatorias

## Archivos temporales

Los scripts de exploración (Playwright specs, configs) van SIEMPRE a `$TMPDIR`, nunca dentro del proyecto:

```bash
# CORRECTO
cat > "$TMPDIR/explore-session.spec.ts" << 'SCRIPT'
...
SCRIPT
npx playwright test --config {PLAYWRIGHT_CONFIG} "$TMPDIR/explore-session.spec.ts"

# PROHIBIDO — rompe lint y contamina el repo
Write(tests/explore-session.spec.ts)
Write(tests/explore-config.ts)
```

## Limpieza — Nunca usar `rm` directo

El sistema de permisos bloquea `rm` y requiere confirmación del usuario, interrumpiendo la automatización del loop. Usar siempre los scripts dedicados:

**Explore** — limpia todos los explore-* de $TMPDIR:
```bash
bash .proactive-qa-scripts/cleanup-explore.sh
```

**Autofix / general** — borra archivos específicos por nombre en $TMPDIR (sin paths, solo nombres):
```bash
bash .proactive-qa-scripts/cleanup-tmpdir.sh file1.ts file2.spec.ts screenshot.png
```

## Commits — Usar script dedicado

Nunca usar `git add`/`git commit` directamente — triggean permisos del sandbox que rompen `/loop`:
```bash
bash .proactive-qa-scripts/commit.sh "fix(proactive-qa): descripción" archivo1 archivo2
```

## Resumen

| Acción | Correcto | Prohibido |
|--------|----------|-----------|
| Escribir specs | `$TMPDIR/explore-*.spec.ts` | `tests/explore-*.ts` |
| Limpiar explore | `bash .proactive-qa-scripts/cleanup-explore.sh` | `rm -f ...` |
| Borrar archivo temp | `bash .proactive-qa-scripts/cleanup-tmpdir.sh nombre.ts` | `rm -f $TMPDIR/nombre.ts` |
| Commit | `bash .proactive-qa-scripts/commit.sh "msg" files` | `git add && git commit` |
