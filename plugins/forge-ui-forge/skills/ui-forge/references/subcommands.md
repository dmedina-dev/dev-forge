# ui-forge subcommands

## serve

Start the dev server for hot-reload prototyping. Requires Monitor tool.

```bash
Monitor(
  command: "bash '${CLAUDE_PLUGIN_ROOT}/skills/ui-forge/scripts/serve.sh'"
)
```

`serve.sh` is a thin wrapper around `serve.py` — the `bash` path is stable and pre-approvable (add `bash **/ui-forge/scripts/*.sh` to `permissions.allow`) so no approval dialog on start/stop/status.

The server:
- Serves `.ui-forge/` on `http://127.0.0.1:4269`
- Prints clickable URLs for any existing `02-forge.html` screens
- Accepts `POST /forge/feedback` — writes `feedback/round-NN.json` + `feedback/latest.json`
- Prints `[ui-forge] feedback screen=<id> round=<n> pins=<k>` to stdout on each POST — this is the Monitor event that triggers you to act
- Serves `GET /forge/reload` (SSE) — pushes reload events when `02-forge.html` mtime changes
- Writes PID to `.ui-forge/.server.pid`

### On feedback event

Monitor delivers a compact, actionable block on every POST to `/forge/feedback`. Example:

```
[ui-forge] feedback screen=portfolio-overview round=5 pins=3 new=2 file=.../feedback/round-05.json
[ui-forge:pin] --- #2 [change] scenario=happy point @ (120,340)
[ui-forge:pin]     selector: main > section.holdings > div.kpi-card > span.delta
[ui-forge:pin]     comment: El delta negativo debería ser rojo, ahora está verde
[ui-forge:pin]     text:    +2.4% vs ayer
[ui-forge:pin]     html:    <span class="delta text-green-500">+2.4% vs ayer</span>
[ui-forge:pin] --- #3 [extract-as-component] scenario=happy region 480x280 @ (100,500)
[ui-forge:pin]     selector: section.holdings > div.table-wrapper
[ui-forge:pin]     comment: Extraer esta tabla como data-table-dense
[ui-forge:pin]     text:    Ticker Nombre Peso Precio medio Precio actual PL abs PL %
[ui-forge:pin]     html:    <div class="table-wrapper overflow-x-auto"><table>...</table></div>
[ui-forge] round 5 ready — apply changes and save 02-forge.html
```

**All the information you need is in stdout.** You do NOT need to read `latest.json` or the round file for the normal case — parse the `[ui-forge:pin]` lines directly.

Only fetch more detail when:
- The `html:` line is truncated (ends with `…`) and you need the full `outerHTML`
- You need a pin sent in a previous round (stdout only emits new pins from this round)

Use `scripts/show-pin.py` for that — a stable, pre-approvable script so you don't have to craft ad-hoc `python3 -c "…"` commands (every fresh command costs a user approval). Examples:

```bash
# List pin ids available in the latest round
python3 "${CLAUDE_PLUGIN_ROOT}/skills/ui-forge/scripts/show-pin.py" portfolio-overview --ids

# Pretty-print one specific pin with full untruncated html
python3 "${CLAUDE_PLUGIN_ROOT}/skills/ui-forge/scripts/show-pin.py" portfolio-overview --pin 7

# Look at an older round
python3 "${CLAUDE_PLUGIN_ROOT}/skills/ui-forge/scripts/show-pin.py" portfolio-overview --round 3

# JSON for machine parsing
python3 "${CLAUDE_PLUGIN_ROOT}/skills/ui-forge/scripts/show-pin.py" portfolio-overview --pin 7 --json
```

**Pre-approval tip for users:** adding `python3 **/ui-forge/scripts/show-pin.py *` to `permissions.allow` in `.claude/settings.local.json` makes every future invocation friction-free.

Apply the requested changes to `02-forge.html` by pin type:
- `change` → modify the element or layout as described
- `extract-as-component` → note for Phase 4 distillation
- `replace-with-registry` → swap in the registry component
- `token-issue` → fix token usage
- `data-issue` → fix mock data or schema

Write the updated `02-forge.html` — the server detects the mtime change and the browser auto-reloads via SSE. The user sees changes appear without switching to the chat.

## stop

Kill the running dev server (idempotent: no-op if nothing is running).

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/ui-forge/scripts/stop.sh"
```

Output: `[ui-forge] stopped server (PID …)` or `[ui-forge] no server running`.

## status

Check if the server is running.

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/ui-forge/scripts/status.sh"
```

Output: `[ui-forge] running (PID … ) on http://127.0.0.1:4269` or `[ui-forge] not running`. Stale PID files get cleaned up automatically.

## refresh

Force-refresh the runtime assets (`overlay.js` and anything else in the plugin's `assets/`) in the consumer's `.ui-forge/assets/`. Use this when the plugin's overlay.js has been updated but the consumer still has the old copy (the initial bootstrap only copies if missing, never overwrites).

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/ui-forge/scripts/refresh-assets.sh"
```

**Does NOT touch:** `config.json`, `registry/`, `screens/`, `fixtures/`, `feedback/`. Only `.ui-forge/assets/*` is overwritten.

After refresh, tell the user to **hard-reload the browser (Cmd+Shift+R)** to bypass the browser cache. If serve.py is running, no restart needed — it serves the refreshed file on next request.
