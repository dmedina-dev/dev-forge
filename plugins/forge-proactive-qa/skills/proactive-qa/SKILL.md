---
name: proactive-qa
description: >
  Proactive QA agent that explores web apps with Playwright to find bugs (usability, functionality, layout)
  and auto-fixes them. Three modes: "explore" (browse and log issues), "autofix" (fix pending issues with
  validation and retry), and "cycle" (alternates explore/autofix automatically). Use this skill when:
  /proactive-qa, the user wants autonomous bug hunting, proactive testing, or automated exploration of the
  web interface. Also use when the user mentions "/loop" with QA, testing exploration, or proactive bug fixing.
  Invoke with: /proactive-qa explore, /proactive-qa autofix, or /proactive-qa cycle.
---

# Proactive QA

Autonomous quality assurance skill with three modes. Designed to run via `/loop`.

- **Explore**: Browses the app with Playwright, logs issues in the bitacora directory
- **Autofix**: Picks up pending issues, fixes them, validates, commits or rolls back
- **Cycle**: Alternates between explore and autofix automatically (ideal for `/loop`)

Both modes write to the same bitacora and notify via Telegram.

### Quick start

1. Configure the project variables (see below)
2. Run `/proactive-qa init` to discover routes and verify prerequisites
3. Start the loop: `/loop 15m /proactive-qa cycle`

---

## Project Configuration

Before using this skill, the project must define these values in its CLAUDE.md or a project-level config. The skill references them as `{PLACEHOLDER}` throughout its documentation.

| Variable | Description | Example |
|----------|-------------|---------|
| `{DEV_SERVER_START}` | Command to start dev servers | `pnpm dev`, `npm run dev`, `make serve` |
| `{DEV_SERVER_STOP}` | Command to stop dev servers | `pnpm dev:stop`, `pkill -f "next dev"` |
| `{API_HEALTH_URL}` | API health check endpoint | `http://localhost:3001/health` |
| `{FRONTEND_URL}` | Frontend base URL | `http://localhost:5173` |
| `{PLAYWRIGHT_CONFIG}` | Path to Playwright config | `tests/e2e/playwright.config.ts` |
| `{AUTH_STATE}` | Path to Playwright auth state | `tests/e2e/.auth/user.json` |
| `{LINT_CMD}` | Lint command | `pnpm lint`, `npm run lint` |
| `{TEST_CMD}` | Test command | `pnpm test`, `npm test` |
| `{BITACORA_DIR}` | Directory for issue logs | `docs/proactive-works/` |

---

## Safety Rules

- **NEVER change git branch.** All work happens on the current branch.
- **NEVER use `cd`.** Run everything from project root.
- **Use `bash ${CLAUDE_PLUGIN_ROOT}/scripts/commit.sh`** for all commits. Never raw git commands (they trigger permission prompts that break automation).
- Respect all existing hooks (lint, tests, protect-files).

## Temporary Files — ALWAYS use $TMPDIR

Write ALL temp scripts and screenshots to `$TMPDIR` (or `/private/tmp/claude/` as fallback). Never write temporary files inside the project tree.

```bash
# CORRECT
cat > "$TMPDIR/explore-session.spec.ts" << 'SCRIPT'
...
SCRIPT
npx playwright test --config {PLAYWRIGHT_CONFIG} "$TMPDIR/explore-session.spec.ts"

# FORBIDDEN — pollutes repo, breaks lint
Write(tests/e2e/explore-session.spec.ts)
```

## Cleanup — NEVER use `rm` directly

The sandbox blocks `rm` and requires user confirmation, breaking automation. Always use the dedicated scripts:

| Action | Command |
|--------|---------|
| Clean all explore temp files | `bash ${CLAUDE_PLUGIN_ROOT}/scripts/cleanup-explore.sh` |
| Delete specific files from $TMPDIR | `bash ${CLAUDE_PLUGIN_ROOT}/scripts/cleanup-tmpdir.sh file1.ts file2.png` |

These rules apply to **all agents and subagents** — fixer agents, validator agents, and the orchestrator itself.

## Notifications

### Setup — Chat ID Resolution

At the start of each session, resolve the notification target:

1. Read `~/.claude/channels/telegram/access.json` → extract `allowFrom[0]` as NOTIFY_CHAT_ID
2. If access.json is missing or `allowFrom` is empty, check project `.env` for `TELEGRAM_CHAT_ID`
3. If neither available, skip all notifications — log to transcript only

### Dispatch Rule

For every notification below:

> **Channel mode** (the `mcp__telegram__reply` tool is available):
> Call `reply` with `chat_id=NOTIFY_CHAT_ID`, `text=<message>`, `files=<screenshot paths if any>`, `format="markdownv2"`.
> Screenshots from `$TMPDIR` can be attached directly via the `files` parameter.
>
> **Fallback** (no MCP reply tool):
> Run: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/telegram-notify.sh "<type>" "<text-only message>"`
> Screenshots cannot be sent in fallback mode — mention file paths in the text.

### Notification Types

**1. Explore results** (`explore`):
```
🔍 *Proactive QA* — explore
📂 Branch: `{branch}`

Exploración completada. {N} rutas revisadas, {M} problemas nuevos encontrados.
Categorías: {list}
```
Attach: screenshots from `$TMPDIR/screenshot-*.png`

**2. Fix success** (`fix-ok`):
```
✅ *Proactive QA* — fix-ok
📂 Branch: `{branch}`

PWI-{id} arreglado: {título}
```

**3. Fix failure** (`fix-fail`):
```
❌ *Proactive QA* — fix-fail
📂 Branch: `{branch}`

PWI-{id} necesita revisión humana: {título}. 3 intentos fallidos.
```

**4. Cycle complete** (`cycle-done`):
```
🏁 *Proactive QA* — cycle-done
📂 Branch: `{branch}`

Ciclo completado. {X} arreglados, {Y} fallidos, {Z} pendientes.
```

**5. Error** (`error`):
```
🚨 *Proactive QA* — error
📂 Branch: `{branch}`

{error description}
```

## Server Health Check

Before any Playwright run, verify dev servers are up:

```bash
curl -s {API_HEALTH_URL} > /dev/null 2>&1 && echo "API OK" || echo "API DOWN"
curl -s {FRONTEND_URL} > /dev/null 2>&1 && echo "Frontend OK" || echo "Frontend DOWN"
```

If down, attempt recovery: `{DEV_SERVER_STOP}` then `{DEV_SERVER_START} & sleep 10`. If still down after retry, log a critical build issue in the bitacora and exit.

## Auth State

Playwright auth files must exist at `{AUTH_STATE}`. Generate them according to your project's auth setup before first use.

---

## Bitacora Format

All issues are logged in `{BITACORA_DIR}/YYYY-MM-DD-HHmm-explore.md`:

```markdown
# Exploración proactiva — YYYY-MM-DD HH:mm

## Categorías verificadas
1, 2, 3 (siempre) + 10, 12 (rotación)

## Rutas exploradas

| Ruta | Estado | Notas |
|------|--------|-------|
| /dashboard | OK | Sin problemas |
| /transactions | PROBLEMA | Ver PWI-xxx |

## Problemas identificados

### PWI-{timestamp}-001: Título descriptivo

- **Estado**: pendiente
- **Ruta**: /transactions
- **Tipo**: usabilidad | funcionamiento | maquetación
- **Severidad**: critica | alta | media | baja
- **Descripción**: Qué se observó
- **Cómo reproducir**: Pasos
- **Corrección sugerida**: Qué archivo(s) cambiar
- **Intentos**: 0/3
- **Historial de intentos**: (vacío)
```

The `PWI-{timestamp}-NNN` ID uses the file's timestamp prefix + sequential number.

### Finding pending work

```bash
grep -l "Estado.*pendiente\|Estado.*fallido[^-]" {BITACORA_DIR}/*.md
```

### Updating issues

Use the Edit tool to update specific fields. Always preserve `Historial de intentos`.

---

## Mode: Cycle (alternating explore/autofix)

**Invocation**: `/loop 15m /proactive-qa cycle`

Automatically alternates between explore and autofix on each invocation. Uses a state file (`.cycle-state` in the plugin root) to track which mode runs next.

### How it works

1. Read `${CLAUDE_PLUGIN_ROOT}/.cycle-state` (defaults to `explore` if missing)
2. If state = `explore`: run explore mode, then write `autofix` to state file
3. If state = `autofix`: run autofix mode, then write `explore` to state file
4. After finishing, run cleanup + `/clear` as usual

### State file management

```bash
# Read current state (default: explore)
STATE=$(cat "${CLAUDE_PLUGIN_ROOT}/.cycle-state" 2>/dev/null || echo "explore")

# After completing, toggle state
if [ "$STATE" = "explore" ]; then
  echo "autofix" > "${CLAUDE_PLUGIN_ROOT}/.cycle-state"
else
  echo "explore" > "${CLAUDE_PLUGIN_ROOT}/.cycle-state"
fi
```

The state file should be gitignored. If autofix finds no pending issues, it skips silently and the next cycle will explore again.

---

## Mode: Explore

**Invocation**: `/proactive-qa explore` or `/loop 15m /proactive-qa explore`

**Time limit**: 15 minutes max per session.

Read `references/explore.md` for the full flow: loading prior coverage, planning which routes/categories to check, running Playwright scripts, logging findings, and cleanup.

Key reference: `references/explore-checklist.md` has the verification categories and Playwright templates.

**After finishing**: run cleanup + `/clear` to free context for next iteration.

---

## Mode: Autofix

**Invocation**: `/proactive-qa autofix` or `/loop 10m /proactive-qa autofix`

Read `references/autofix.md` for the full flow: loading pending issues, launching fixer/validator agents, processing results (commit or rollback), and the 3-attempt retry cycle.

**After finishing**: notify via Telegram + `/clear` to free context for next iteration.

---

## Common Rules for All Subagents

Every agent prompt (fixer, validator) MUST include these rules:

```
- Never use cd, run everything from project root
- Follow project conventions in CLAUDE.md
- Write temp files to $TMPDIR, NEVER inside the project tree
- NEVER use rm to delete files. Use:
  bash ${CLAUDE_PLUGIN_ROOT}/scripts/cleanup-tmpdir.sh file1.ts file2.png
- Do NOT change branch
- Do NOT commit — the orchestrator handles commits
```

## Setup — Permissions for Autonomous Execution

Add these to your project's `.claude/settings.json` to allow unattended `/loop` execution:

```json
{
  "permissions": {
    "allow": [
      "Bash(bash ${CLAUDE_PLUGIN_ROOT}/scripts/commit.sh:*)",
      "Bash(bash ${CLAUDE_PLUGIN_ROOT}/scripts/cleanup-explore.sh:*)",
      "Bash(bash ${CLAUDE_PLUGIN_ROOT}/scripts/cleanup-tmpdir.sh:*)",
      "Bash(bash ${CLAUDE_PLUGIN_ROOT}/scripts/telegram-notify.sh:*)"
    ]
  }
}
```
