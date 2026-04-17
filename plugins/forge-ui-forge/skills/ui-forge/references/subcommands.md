# ui-forge subcommands

## serve

Start the dev server for hot-reload prototyping. Requires Monitor tool.

```bash
Monitor(
  command: "python3 '${CLAUDE_PLUGIN_ROOT}/skills/ui-forge/scripts/serve.py'"
)
```

The server:
- Serves `.ui-forge/` on `http://127.0.0.1:4269`
- Prints clickable URLs for any existing `02-forge.html` screens
- Accepts `POST /forge/feedback` — writes `feedback/round-NN.json` + `feedback/latest.json`
- Prints `[ui-forge] feedback screen=<id> round=<n> pins=<k>` to stdout on each POST — this is the Monitor event that triggers you to act
- Serves `GET /forge/reload` (SSE) — pushes reload events when `02-forge.html` mtime changes
- Writes PID to `.ui-forge/.server.pid`

### On feedback event

When Monitor delivers a `[ui-forge] feedback` line:

1. Read `.ui-forge/screens/<screen-id>/feedback/latest.json` to get the filename
2. Read the full round file (e.g., `feedback/round-03.json`) — contains pins with types, comments, selectors, coordinates
3. Apply the requested changes to `02-forge.html`:
   - `change` pins → modify the element or layout as described
   - `extract-as-component` pins → note for Phase 4 destillation
   - `replace-with-registry` pins → swap in the registry component
   - `token-issue` pins → fix token usage
   - `data-issue` pins → fix mock data or schema
4. Write the updated `02-forge.html` — the server detects the mtime change and the browser auto-reloads via SSE

The user sees changes appear in the browser without switching to the chat.

## stop

Kill the running dev server.

```bash
kill "$(cat .ui-forge/.server.pid)" 2>/dev/null && rm -f .ui-forge/.server.pid
```

Confirm to the user that the server has stopped.

## status

Check if the server is running.

```bash
if [ -f .ui-forge/.server.pid ] && kill -0 "$(cat .ui-forge/.server.pid)" 2>/dev/null; then
  echo "ui-forge server running (PID $(cat .ui-forge/.server.pid)) on port 4269"
else
  echo "ui-forge server not running"
  rm -f .ui-forge/.server.pid 2>/dev/null
fi
```
