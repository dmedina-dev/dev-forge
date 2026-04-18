# ui-forge subcommands

## serve

Start the dev server for hot-reload prototyping. Requires Monitor tool.

```bash
Monitor(
  command: "bash '${CLAUDE_PLUGIN_ROOT}/skills/ui-forge/scripts/serve.sh'"
)
```

`serve.sh` is a thin wrapper around `serve.py` — the `bash` path is stable and pre-approvable (add `bash **/ui-forge/scripts/*.sh` to `permissions.allow`) so no approval dialog on start/stop/status.

**On startup, the server emits a single stdout line listing every discoverable URL:**

```
[ui-forge] serving http://127.0.0.1:4269 | forge[portfolio-overview]=http://.../02-forge.html | output[portfolio-overview]=http://.../output/screen.html | catalog=http://.../registry/catalog.html
```

Parse that line and **present the URLs to the user as a clickable table** with these exact labels + icons (only include the rows whose URL appears in the stdout):

| Recurso | URL |
|---------|-----|
| 🔧 Forge (hot-reload) | `http://…/02-forge.html` |
| 🎨 Screen destilada | `http://…/output/screen.html` |
| 📁 Catálogo | `http://…/registry/catalog.html` |

- One row per URL found. If there are several `forge[...]` entries (multiple screens), render a row per screen and include the screen id in the label (e.g. `🔧 Forge · portfolio-overview`).
- The URLs must be real clickable links (markdown autolinks), not wrapped in prose.
- Keep the icon + label exactly as shown — users recognize the visual cues between sessions.

The server:
- Serves `.ui-forge/` on `http://127.0.0.1:4269`
- Prints clickable URLs for any existing `02-forge.html` screens
- Accepts `POST /forge/feedback` — writes `feedback/round-NN.json` + `feedback/latest.json`
- Prints `[ui-forge] feedback screen=<id> round=<n> pins=<k>` to stdout on each POST — this is the Monitor event that triggers you to act
- Serves `GET /forge/reload` (SSE) — pushes reload events when `02-forge.html` mtime changes
- Writes PID to `.ui-forge/.server.pid`

### On feedback event

Monitor surfaces each stdout line as its own event, so the server emits exactly ONE line per feedback POST. Example:

```
[ui-forge] round=5 screen=portfolio-overview new=2 total=3 | #2[change] @(120,340) "El delta negativo debería ser rojo, ahora está verde" || #3[extract-as-component] 480x280@(100,500) "Extraer como data-table-dense" | details: show-pin.py portfolio-overview --round 5
```

Format:
- Header: `round=N screen=<id> new=K total=T`
- One `#id[type] location "comment"` segment per new pin, separated by `||`
- Location: `@(x,y)` for point pins, `WxH@(x,y)` for area pins
- Comment truncated to 140 chars
- Footer: ready-to-run `show-pin.py` hint

**This one line is enough for most changes.** Use `scripts/show-pin.py` whenever you need more context:

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
