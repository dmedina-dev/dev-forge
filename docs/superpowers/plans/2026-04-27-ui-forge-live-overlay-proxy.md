# forge-ui-forge — Live Overlay Proxy Mode Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Designed to be executable by forge-executor's wave runner.

**Goal:** Add a "live mode" to forge-ui-forge that proxies the user's running dev server (any stack) on a separate port, injects `overlay.js` into HTML responses, and collects pin feedback into `.ui-forge/live/<session-id>/round-NN.json` — without any code change in the consumer app and trivially revertible via a single `git revert`.

**Architecture:** A new `aiohttp`-based async server (`scripts/live/live.py`) acts as an HTTP+WebSocket reverse proxy in front of `--target <upstream-url>`. HTML responses get a small `<script>` block injected before `</body>` that loads `overlay.js` (served by the proxy from `.ui-forge/assets/`) and primes it with `window.UIFORGE_MODE='live'`, a session id, and the upstream host. WebSocket upgrades are forwarded bidirectionally so HMR keeps working. `POST /forge/feedback` is intercepted (not proxied) and writes round JSON to `.ui-forge/live/<session-id>/`. Everything new lives under `scripts/live/`, behind a markered SKILL.md section, and gated in `overlay.js` by `window.UIFORGE_MODE === 'live'` — the existing prototype flow (`serve.py`, `serve.sh`, `stop.sh`, `status.sh`) is **not modified**.

**Tech Stack:** Python 3.10+, `aiohttp` (single new dependency, optional), bash for lifecycle wrappers, vanilla JS for overlay branch, pytest + pytest-asyncio for tests.

**Open design question — answer:** The first cut is **option (a) feedback collector only**. Live-mode pins land as JSON files; Claude reads them on demand (via Monitor stdout trigger or `show-pin.py --live`) and decides what to do next. **Claude does NOT auto-edit `src/` from live pins in v1.** Option (b) auto-editing src/ is recorded as a v2 follow-up.

**Rollback contract:** Every change in this plan goes into a single squashed commit titled `feat(ui-forge): live overlay proxy mode`. Rolling back = `git revert <sha>`. The rollback removes the `scripts/live/` directory, the markered SKILL.md section, the `overlay.js` live branch, and reverts the version bump. Prototype mode keeps working at every wave boundary (acceptance criterion enforced per wave).

---

## File map

### Files to create

```
plugins/forge-ui-forge/skills/ui-forge/scripts/live/
├── live.py                    # aiohttp proxy + feedback intercept
├── live.sh                    # preflight aiohttp + exec live.py
├── stop-live.sh               # kill PID at .ui-forge/.live-server.pid
├── status-live.sh             # report live proxy status
└── show-pin-live.py           # variant of show-pin.py for live sessions

plugins/forge-ui-forge/tests/live/
├── conftest.py                # pytest fixtures: stub upstream, temp .ui-forge
├── test_http_passthrough.py
├── test_html_injection.py
├── test_static_endpoints.py
├── test_websocket_proxy.py
├── test_feedback_intercept.py
├── test_preflight.py
├── test_shutdown.py
└── README.md                  # how to run: `python3 -m pytest plugins/forge-ui-forge/tests/live/`
```

### Files to modify

```
plugins/forge-ui-forge/skills/ui-forge/SKILL.md
  → add markered section <!-- ui-forge:live:start --> ... <!-- ui-forge:live:end -->
  → add 3 rows to the Subcommands table (live, stop-live, status-live)

plugins/forge-ui-forge/skills/ui-forge/references/subcommands.md
  → add "## live", "## stop-live", "## status-live" sections at end

plugins/forge-ui-forge/skills/ui-forge/assets/overlay.js
  → add live branch gated by window.UIFORGE_MODE === 'live'
  → STORAGE_KEY switches to `uiforge:live:${host}:pins`
  → buildPayload includes mode, sessionId, host, path
  → setupSSE skipped in live mode
  → scenario UI hidden in live mode

plugins/forge-ui-forge/.claude-plugin/plugin.json
  → version: 0.3.0 → 0.4.0

.claude-plugin/marketplace.json
  → forge-ui-forge entry: version 0.3.0 → 0.4.0
  → description suffix: ", plus live mode that proxies an existing dev server and injects the overlay (opt-in, requires aiohttp)"
```

### Files NOT to modify (rollback safety)

```
plugins/forge-ui-forge/skills/ui-forge/scripts/serve.py    # stdlib-only, untouched
plugins/forge-ui-forge/skills/ui-forge/scripts/serve.sh
plugins/forge-ui-forge/skills/ui-forge/scripts/stop.sh
plugins/forge-ui-forge/skills/ui-forge/scripts/status.sh
plugins/forge-ui-forge/skills/ui-forge/scripts/refresh-assets.sh
plugins/forge-ui-forge/skills/ui-forge/scripts/init-registry.sh
plugins/forge-ui-forge/skills/ui-forge/scripts/show-pin.py
plugins/forge-ui-forge/skills/ui-forge/templates/*
```

---

## Wire formats

### Init payload injected into HTML responses

Right before `</body>` (or appended at end if no `</body>` — handle gracefully):

```html
<script>
  window.UIFORGE_MODE = 'live';
  window.UIFORGE_SESSION_ID = '2026-04-27T143052';     // or user-supplied --name
  window.UIFORGE_LIVE_HOST = 'localhost:3000';         // upstream host:port
  window.UIFORGE_LIVE_PATH = '/dashboard';             // current path
  window.UIFORGE_FEEDBACK_URL = '/forge/feedback';     // proxy-local
</script>
<script src="/forge/__overlay.js" defer></script>
```

Markers `<!-- ui-forge:live:injected:start -->` ... `<!-- ui-forge:live:injected:end -->` wrap the injected block so it's grep-able and can be re-detected to avoid double-injection on retries.

### Live-mode feedback payload (overlay → proxy)

```json
{
  "mode": "live",
  "sessionId": "2026-04-27T143052",
  "host": "localhost:3000",
  "path": "/dashboard",
  "round": 3,
  "exportedAt": "2026-04-27T15:02:11.000Z",
  "pinCount": 4,
  "newPinCount": 1,
  "newPinIds": [4],
  "pins": [ /* same shape as prototype-mode pins */ ]
}
```

### Live-mode stdout trigger (proxy → Monitor → Claude)

```
[ui-forge] live round=3 session=2026-04-27T143052 host=localhost:3000 path=/dashboard new=1 total=4 | #4[change] @(120,340) "El header debería ser sticky" | details: show-pin-live.py 2026-04-27T143052 --round 3
```

### On-disk layout written by live mode

```
<project>/.ui-forge/live/
├── <session-id>/
│   ├── round-01.json
│   ├── round-02.json
│   ├── ...
│   └── latest.json          { file, sessionId, host, path, round, pinCount, receivedAt }
└── .live-server.pid         (NOT inside session dir — one PID per project)
```

PID file lives at `.ui-forge/.live-server.pid` (not `.server.pid` — that's the prototype server). Both can run simultaneously (port 4269 vs 4270).

---

## Wave 1: Skeleton + preflight + HTTP passthrough

**Deliverable:** A live proxy that forwards HTTP requests to the upstream verbatim. No HTML injection yet, no WS, no feedback intercept. `live.sh` preflights `aiohttp` and aborts cleanly when missing. PID file written. Startup line emitted.

**Files to create:**
- `plugins/forge-ui-forge/skills/ui-forge/scripts/live/live.py`
- `plugins/forge-ui-forge/skills/ui-forge/scripts/live/live.sh`
- `plugins/forge-ui-forge/tests/live/conftest.py`
- `plugins/forge-ui-forge/tests/live/test_preflight.py`
- `plugins/forge-ui-forge/tests/live/test_http_passthrough.py`
- `plugins/forge-ui-forge/tests/live/README.md`

**Acceptance criteria:**
- `bash live.sh --target http://nonexistent:9999` exits with `[ui-forge] live mode requires aiohttp. Install with: pip install aiohttp` when aiohttp is not importable.
- With aiohttp installed, `live.sh --target <stub-upstream>` starts the proxy on `127.0.0.1:4270`, prints `[ui-forge] live serving http://127.0.0.1:4270 → <target> (session=<iso-ts>)`, and writes PID to `.ui-forge/.live-server.pid`.
- `GET /any/path?q=1` to the proxy returns the upstream body, status, and headers verbatim (Content-Type preserved, content-length recomputed for safety).
- `POST /api/echo` forwards the body to upstream and returns the upstream response.
- Prototype-mode test still passes: `bash scripts/serve.sh` (in a temp `.ui-forge/`) starts on 4269 — sanity-check that nothing in this wave touched `serve.py` or `serve.sh`.

### Task 1.1: Test fixtures — stub upstream + temp .ui-forge

**Files:**
- Create: `plugins/forge-ui-forge/tests/live/conftest.py`
- Create: `plugins/forge-ui-forge/tests/live/README.md`

- [ ] **Step 1: Write `conftest.py` with `stub_upstream` fixture.**
  Spins up an `aiohttp.web.Application` on a free port returning fixed JSON for `/api/echo`, fixed HTML for `/index.html` (containing `<html><body><h1>upstream</h1></body></html>`), and an echo WebSocket at `/ws`. Yield base URL.
- [ ] **Step 2: Add `tmp_uiforge` fixture.**
  `tmp_path / ".ui-forge"`, mkdir, chdir into the parent (so `Path.cwd() / ".ui-forge"` resolves correctly). Yield path. Restore cwd in teardown.
- [ ] **Step 3: Add `live_proxy` fixture.**
  Imports `live.py`, builds the aiohttp Application with `target=stub_upstream`, returns aiohttp `TestClient` wrapping it. Skipped automatically if aiohttp unavailable (`pytest.importorskip("aiohttp")`).
- [ ] **Step 4: Write `tests/live/README.md`** — one paragraph: "Run with `python3 -m pip install aiohttp pytest pytest-asyncio` then `python3 -m pytest plugins/forge-ui-forge/tests/live/`. Tests are skipped automatically when aiohttp is missing."
- [ ] **Step 5: Verify pytest collects the conftest** — `python3 -m pytest plugins/forge-ui-forge/tests/live/ --collect-only` lists no errors. Commit.

### Task 1.2: Preflight test (aiohttp missing)

**Files:**
- Create: `plugins/forge-ui-forge/tests/live/test_preflight.py`
- Create: `plugins/forge-ui-forge/skills/ui-forge/scripts/live/live.sh`

- [ ] **Step 1: Write the failing test.**
  `test_preflight_aborts_without_aiohttp` — runs `live.sh --target http://127.0.0.1:9999` in a subprocess with `PYTHONPATH=/dev/null` (or a wrapper python that fails to import aiohttp), asserts exit code != 0 and stdout contains `pip install aiohttp`.
- [ ] **Step 2: Run test to verify it fails** (script doesn't exist yet).
- [ ] **Step 3: Write `live.sh`** — bash script that runs `python3 -c 'import aiohttp'` first; on ImportError prints the error message and exits 1. On success `exec python3 "$SCRIPT_DIR/live.py" "$@"`. Use `set -uo pipefail` + `trap 'exit 0' ERR` ONLY on the cleanup paths, but allow the failure exit code to propagate. Mirror the structure of `serve.sh`.
- [ ] **Step 4: Run test to verify it passes.** Commit.

### Task 1.3: Skeleton live.py — argparse + aiohttp app boots

**Files:**
- Create: `plugins/forge-ui-forge/skills/ui-forge/scripts/live/live.py`

- [ ] **Step 1: Write the failing test** `test_proxy_starts_and_writes_pid` in `test_http_passthrough.py`. Uses `live_proxy` fixture, asserts PID file exists at `.ui-forge/.live-server.pid` and contains the proxy process PID.
- [ ] **Step 2: Run test to verify it fails.**
- [ ] **Step 3: Write `live.py`** with:
  - `argparse`: `--target` (required), `--port` (default 4270), `--name` (default ISO timestamp `time.strftime("%Y-%m-%dT%H%M%S")`).
  - `Path.cwd() / ".ui-forge"` validation (exit 1 with message if missing).
  - `write_pid()` / `remove_pid()` to `.ui-forge/.live-server.pid`.
  - `signal.signal(SIGTERM/SIGINT, cleanup)` calls `remove_pid()` and `sys.exit(0)`.
  - Stdout startup line: `[ui-forge] live serving http://127.0.0.1:{port} → {target} (session={name})`.
  - Empty `aiohttp.web.Application` for now.
- [ ] **Step 4: Run test to verify it passes.** Commit.

### Task 1.4: HTTP passthrough — GET

**Files:**
- Modify: `plugins/forge-ui-forge/skills/ui-forge/scripts/live/live.py`
- Modify: `plugins/forge-ui-forge/tests/live/test_http_passthrough.py`

- [ ] **Step 1: Write the failing test** `test_get_passes_through_to_upstream`. Uses `live_proxy` + `stub_upstream` fixtures; GETs `/api/echo`, asserts body matches the JSON the upstream returns, content-type is `application/json`.
- [ ] **Step 2: Run test to verify it fails.**
- [ ] **Step 3: Implement catch-all GET handler in `live.py`.**
  - Use `aiohttp.ClientSession` (single shared session, created at app startup, closed on shutdown).
  - Forward method, path, query string, headers (drop `Host`, `Connection`, `Upgrade` which aiohttp manages).
  - Stream response body back unmodified.
  - Preserve status code and response headers (drop `Transfer-Encoding`, `Connection`).
- [ ] **Step 4: Run test to verify it passes.** Commit.

### Task 1.5: HTTP passthrough — POST + arbitrary methods

**Files:**
- Modify: `plugins/forge-ui-forge/skills/ui-forge/scripts/live/live.py`
- Modify: `plugins/forge-ui-forge/tests/live/test_http_passthrough.py`

- [ ] **Step 1: Write the failing test** `test_post_forwards_body_and_returns_response`. Stub upstream's `/api/echo` accepts POST, echoes back the JSON body. Test asserts round-trip.
- [ ] **Step 2: Run test to verify it fails** (current handler only does GET).
- [ ] **Step 3: Generalise the handler.** Register the catch-all route with `app.router.add_route('*', '/{path:.*}', handler)`. Inside the handler, read `request.read()` for the body and pass it as `data=` to the client request. Add a second test for `PUT` to confirm.
- [ ] **Step 4: Run test to verify both pass.**
- [ ] **Step 5: Smoke-test that prototype mode is untouched.** Run `bash plugins/forge-ui-forge/skills/ui-forge/scripts/serve.sh` in a temp project — should start on 4269 unchanged. `bash plugins/forge-ui-forge/skills/ui-forge/scripts/stop.sh` cleans up. Commit.

**Wave 1 rollback note:** `rm -rf plugins/forge-ui-forge/scripts/live plugins/forge-ui-forge/tests/live` removes everything new. No other files were modified. Marketplace + plugin.json untouched until Wave 8.

---

## Wave 2: HTML injection

**Deliverable:** When the upstream returns `text/html`, the proxy injects the live-mode init script + `<script src="/forge/__overlay.js">` reference before `</body>`. Non-HTML responses pass through unchanged. Double-injection prevented.

**Files to modify:**
- `plugins/forge-ui-forge/skills/ui-forge/scripts/live/live.py`

**Files to create:**
- `plugins/forge-ui-forge/tests/live/test_html_injection.py`

**Acceptance criteria:**
- HTML responses get exactly one `<!-- ui-forge:live:injected:start -->...<!-- ui-forge:live:injected:end -->` block before `</body>`.
- HTML without `</body>` (rare but possible) gets the block appended at end with a console warning.
- Non-HTML responses (JSON, JS, CSS, images) are byte-identical to upstream.
- Injected init script contains correct session id, host, path values from request context.
- Re-running the proxy on the same response (e.g. retry) does not re-inject (idempotent).

### Task 2.1: Detect text/html and read full body

- [ ] **Step 1: Write the failing test** `test_html_response_gets_overlay_tag_injected`. Stub upstream returns `<html><body><div id="app">x</div></body></html>` with `Content-Type: text/html`. Assert proxy response body contains `<script src="/forge/__overlay.js"` and the `ui-forge:live:injected:start` marker, both before `</body>`.
- [ ] **Step 2: Run test to verify it fails.**
- [ ] **Step 3: In the proxy handler**, when the upstream response Content-Type starts with `text/html`, buffer the entire body, run `_inject_overlay(body, session_id, host, path)`, recompute Content-Length, and send the modified body. Otherwise stream as before.
- [ ] **Step 4: Implement `_inject_overlay`** — find the last `</body>` (case-insensitive), insert the markered block before it. If not found, append at end + log to stderr `[ui-forge] warning: no </body> in <upstream-path> — overlay appended at end`.
- [ ] **Step 5: Run test to verify it passes.** Commit.

### Task 2.2: Non-HTML responses unchanged

- [ ] **Step 1: Write the failing test** `test_json_response_passes_through_byte_for_byte`. Stub upstream returns JSON. Assert proxy response body equals upstream body exactly (no injection, no marker).
- [ ] **Step 2: Run test to verify it passes** (should already pass — sanity check).
- [ ] **Step 3: Add another test** `test_javascript_response_passes_through_byte_for_byte` for `application/javascript` to confirm we don't accidentally inject into JS files.
- [ ] **Step 4: Run both tests, both green.** Commit.

### Task 2.3: Idempotent injection (no double-inject on retry)

- [ ] **Step 1: Write the failing test** `test_html_already_containing_marker_is_not_reinjected`. Stub upstream returns HTML that already has `<!-- ui-forge:live:injected:start -->` (e.g. cached version). Assert proxy returns body unchanged, no second marker added.
- [ ] **Step 2: Run test to verify it fails** (current code injects unconditionally).
- [ ] **Step 3: In `_inject_overlay`**, early-return if marker is already present in the body.
- [ ] **Step 4: Run test to verify it passes.** Commit.

### Task 2.4: Init payload values

- [ ] **Step 1: Write the failing test** `test_injected_init_script_has_correct_session_host_path`. Start proxy with `--name my-session --target http://localhost:3000`, GET `/dashboard?x=1`. Assert injected `<script>` contains `window.UIFORGE_SESSION_ID = "my-session"`, `window.UIFORGE_LIVE_HOST = "localhost:3000"`, `window.UIFORGE_LIVE_PATH = "/dashboard"`.
- [ ] **Step 2: Run test to verify it fails** (current code uses placeholders).
- [ ] **Step 3: Pass session_id, target_host, request.path to `_inject_overlay`** and string-format them safely (use `json.dumps()` on each value to escape quotes).
- [ ] **Step 4: Run test to verify it passes.**
- [ ] **Step 5: Smoke-test prototype mode untouched** — `serve.sh` still works. Commit.

**Wave 2 rollback note:** Same as Wave 1 — drop the live/ dir and the test/ dir. Prototype mode never depended on injection logic.

---

## Wave 3: Static endpoints — overlay.js + init helper

**Deliverable:** The proxy serves `GET /forge/__overlay.js` (from `.ui-forge/assets/overlay.js`) so the injected `<script src>` resolves. Returns 404 if asset missing with a helpful error pointing the user at `init-registry.sh`.

**Files to modify:**
- `plugins/forge-ui-forge/skills/ui-forge/scripts/live/live.py`

**Files to create:**
- `plugins/forge-ui-forge/tests/live/test_static_endpoints.py`

**Acceptance criteria:**
- `GET /forge/__overlay.js` returns 200 with `Content-Type: application/javascript` and the file body.
- Missing asset returns 503 with body `[ui-forge] overlay.js not found at .ui-forge/assets/overlay.js — run init-registry.sh first`.
- The `/forge/__overlay.js` route takes precedence over the catch-all proxy route (it never reaches the upstream).

### Task 3.1: Serve overlay.js from .ui-forge/assets/

- [ ] **Step 1: Write the failing test** `test_overlay_js_endpoint_returns_file`. Uses `tmp_uiforge` to create `.ui-forge/assets/overlay.js` with body `// fake overlay`. GET `/forge/__overlay.js` on the proxy. Assert 200, body == `// fake overlay`, content-type starts with `application/javascript`.
- [ ] **Step 2: Run test to verify it fails** (currently catch-all proxies to upstream and 404s).
- [ ] **Step 3: Register a specific route** `app.router.add_get('/forge/__overlay.js', _serve_overlay)` BEFORE the catch-all. Read the file, return as `aiohttp.web.Response`.
- [ ] **Step 4: Run test to verify it passes.** Commit.

### Task 3.2: Helpful error when overlay missing

- [ ] **Step 1: Write the failing test** `test_overlay_js_missing_returns_503_with_hint`. Don't create the asset. GET `/forge/__overlay.js`. Assert 503 + body contains `init-registry.sh`.
- [ ] **Step 2: Run test to verify it fails** (raw FileNotFoundError → 500).
- [ ] **Step 3: Wrap in try/except FileNotFoundError**, return `web.Response(status=503, text='[ui-forge] overlay.js not found at .ui-forge/assets/overlay.js — run init-registry.sh first')`.
- [ ] **Step 4: Run test to verify it passes.** Commit.

**Wave 3 rollback note:** Nothing outside `scripts/live/` and `tests/live/` was touched. Two extra route registrations in `live.py`.

---

## Wave 4: WebSocket proxy

**Deliverable:** When the upstream supports WebSockets (e.g. Vite HMR at `/__vite_hmr`, Next at `/_next/webpack-hmr`), the proxy upgrades the connection and bidirectionally pumps messages between client and upstream. HMR works through the proxy.

**Files to modify:**
- `plugins/forge-ui-forge/skills/ui-forge/scripts/live/live.py`
- `plugins/forge-ui-forge/tests/live/conftest.py` (add WS endpoint to stub_upstream)

**Files to create:**
- `plugins/forge-ui-forge/tests/live/test_websocket_proxy.py`

**Acceptance criteria:**
- Client connects to `ws://127.0.0.1:4270/ws` → proxy upgrades → connects to upstream `/ws` → echo round-trip works for text and binary frames.
- Closing the client socket closes the upstream socket (and vice versa) within 1s.
- Multiple concurrent WS connections do not interfere.

### Task 4.1: Stub upstream gets a WebSocket echo endpoint

- [ ] **Step 1: Modify `conftest.py`** to add `/ws` route on the stub upstream. Implementation: `aiohttp.web.WebSocketResponse`, loop over msg, echo back if `msg.type == WSMsgType.TEXT` or `BINARY`. Track a list of active connections so a test can assert "all closed" after teardown.
- [ ] **Step 2: Verify the stub works in isolation** — quick test `test_stub_upstream_ws_echoes` connecting directly to the stub.
- [ ] **Step 3: Commit.**

### Task 4.2: Detect WS upgrade and proxy it

- [ ] **Step 1: Write the failing test** `test_websocket_text_frame_round_trips`. Connect aiohttp ClientSession WS to `ws://127.0.0.1:<proxy>/ws`, send `"hello"`, receive `"hello"` echo.
- [ ] **Step 2: Run test to verify it fails** (current handler returns HTTP 426 or similar from aiohttp ClientSession when upstream tries WS).
- [ ] **Step 3: In the catch-all handler, check `request.headers.get('Upgrade', '').lower() == 'websocket'`.** If so, call a new `_proxy_websocket(request, target)` function.
- [ ] **Step 4: Implement `_proxy_websocket`:**
  - `ws_server = aiohttp.web.WebSocketResponse(); await ws_server.prepare(request)`.
  - Open `ws_client = await session.ws_connect(target_url, headers=forwarded_headers)` to the upstream.
  - Run two concurrent tasks: `client_to_upstream` and `upstream_to_client`, each looping `async for msg in ws` and forwarding by type (TEXT, BINARY, PING, PONG, CLOSE).
  - `await asyncio.wait([t1, t2], return_when=FIRST_COMPLETED)`, then cancel the other and close both sockets.
- [ ] **Step 5: Run test to verify it passes.** Commit.

### Task 4.3: Binary frame round-trip

- [ ] **Step 1: Write the failing test** `test_websocket_binary_frame_round_trips`. Send 1024 random bytes, assert echo is identical.
- [ ] **Step 2: Run test to verify it passes** (Wave 4.2 should already cover binary).
- [ ] **Step 3: If it fails**, fix the BINARY handling branch in the pump.
- [ ] **Step 4: Commit.**

### Task 4.4: Clean close propagates both directions

- [ ] **Step 1: Write the failing test** `test_client_close_closes_upstream`. Connect WS client, close from client side, assert (via stub_upstream's connection tracker) upstream connection is closed within 1s.
- [ ] **Step 2: Write the symmetric test** `test_upstream_close_closes_client`. Have stub upstream close from its side after first message; assert client's `ws.closed` becomes True within 1s.
- [ ] **Step 3: Run tests to verify they fail** (likely if cancellation isn't wired right).
- [ ] **Step 4: Adjust the cancellation logic** — wrap each pump task in try/finally that closes the *other* socket when its own loop exits.
- [ ] **Step 5: Run tests to verify they pass.**
- [ ] **Step 6: Smoke-test prototype mode untouched.** Commit.

**Wave 4 rollback note:** WebSocket logic adds ~80 lines to `live.py`. No new files. Removing the live/ directory undoes everything.

---

## Wave 5: Feedback intercept

**Deliverable:** `POST /forge/feedback` is handled by the proxy itself (not forwarded upstream). Writes `round-NN.json` + `latest.json` to `.ui-forge/live/<session-id>/`. Emits the one-line stdout trigger Monitor parses.

**Files to modify:**
- `plugins/forge-ui-forge/skills/ui-forge/scripts/live/live.py`

**Files to create:**
- `plugins/forge-ui-forge/tests/live/test_feedback_intercept.py`

**Acceptance criteria:**
- POST `/forge/feedback` with valid JSON → 200, file written to `.ui-forge/live/<session-id>/round-NN.json`, `latest.json` updated.
- Round number from payload is zero-padded to 2 digits in the filename.
- Stdout line matches the format spec exactly (the Monitor regex must catch it).
- Invalid JSON → 400.
- Missing `sessionId` → 400.
- POST `/forge/feedback` is NEVER forwarded to upstream (assert by inspecting stub upstream's request log).

### Task 5.1: Route registration + happy path

- [ ] **Step 1: Write the failing test** `test_post_feedback_writes_round_file`. Create `.ui-forge/live/`, POST a payload with `sessionId="s1"`, `round=1`, `pins=[{...}]`. Assert `.ui-forge/live/s1/round-01.json` exists with the payload contents.
- [ ] **Step 2: Run test to verify it fails** (currently catch-all forwards POST upstream → 404).
- [ ] **Step 3: Register `app.router.add_post('/forge/feedback', _handle_feedback)` BEFORE the catch-all.**
  - Validate JSON, validate `sessionId` (regex: alphanumeric + dash/underscore/colon/dot, max 64 chars).
  - Compute `feedback_dir = uiforge / "live" / session_id`, mkdir parents.
  - Write `round-{round:02d}.json` with `payload` (indent=2).
  - Write `latest.json` with `{file, sessionId, host, path, round, pinCount, receivedAt}`.
  - Return 200 JSON `{ok: true, file: "round-01.json"}`.
- [ ] **Step 4: Run test to verify it passes.** Commit.

### Task 5.2: latest.json contents

- [ ] **Step 1: Write the failing test** `test_latest_json_has_metadata`. After two POSTs (round 1 then round 2), assert `latest.json` reflects round 2 — `file: "round-02.json"`, `round: 2`, `host`, `path`, `pinCount` from the latest payload.
- [ ] **Step 2: Run test, verify it fails or passes** (depending on Wave 5.1 details).
- [ ] **Step 3: Adjust as needed.** Commit.

### Task 5.3: Stdout trigger format

- [ ] **Step 1: Write the failing test** `test_post_feedback_emits_monitor_line`. Capture stdout (subprocess `Popen` with PIPE) of the live.py while sending one feedback POST. Assert one line matches:
  ```
  ^\[ui-forge\] live round=\d+ session=\S+ host=\S+ path=\S+ new=\d+ total=\d+ \|.*\| details: show-pin-live\.py \S+ --round \d+$
  ```
- [ ] **Step 2: Run test to verify it fails** (no stdout emission yet).
- [ ] **Step 3: Implement `_format_feedback_line(session_id, round, host, path, pin_count, new_pins)`** — adapted from `serve.py`'s `_format_feedback_line`. Print with `flush=True`.
- [ ] **Step 4: Run test to verify it passes.** Commit.

### Task 5.4: Validation errors

- [ ] **Step 1: Write three failing tests** for `400 on bad JSON`, `400 on missing sessionId`, `400 on session id with invalid chars`.
- [ ] **Step 2: Run tests, verify they fail.**
- [ ] **Step 3: Add validation** at top of `_handle_feedback`. Return `web.json_response({'error': msg}, status=400)`.
- [ ] **Step 4: Run all three, verify pass.** Commit.

### Task 5.5: Feedback never reaches upstream

- [ ] **Step 1: Write the failing test** `test_feedback_post_does_not_reach_upstream`. Modify the stub upstream to record every request. POST `/forge/feedback` to the proxy. Assert the upstream's request log is empty.
- [ ] **Step 2: Run test, verify it passes** (Wave 5.1's specific route should already prevent this — sanity check).
- [ ] **Step 3: Smoke-test prototype mode** — `serve.py`'s feedback POST to `:4269/forge/feedback` still works. Commit.

**Wave 5 rollback note:** Adds ~60 lines to `live.py` plus one test file. No file outside `scripts/live/` and `tests/live/` modified.

---

## Wave 6: Lifecycle scripts + clean shutdown

**Deliverable:** `live.sh`, `stop-live.sh`, `status-live.sh` mirror the existing `serve.sh`/`stop.sh`/`status.sh` pattern. SIGTERM/SIGINT closes WS connections cleanly, closes the shared ClientSession, removes PID file. `show-pin-live.py` reads live-mode rounds.

**Files to create:**
- `plugins/forge-ui-forge/skills/ui-forge/scripts/live/stop-live.sh`
- `plugins/forge-ui-forge/skills/ui-forge/scripts/live/status-live.sh`
- `plugins/forge-ui-forge/skills/ui-forge/scripts/live/show-pin-live.py`
- `plugins/forge-ui-forge/tests/live/test_shutdown.py`

**Files to modify:**
- `plugins/forge-ui-forge/skills/ui-forge/scripts/live/live.py` (add cleanup wiring)

**Acceptance criteria:**
- `bash stop-live.sh` kills the PID at `.ui-forge/.live-server.pid`, removes the file, exits 0. Idempotent.
- `bash status-live.sh` reports running/not-running with PID and port.
- SIGTERM to a running proxy with active WS connections: connections close within 2s, PID file removed, exit code 0.
- `python3 show-pin-live.py <session-id> --round 3` prints the pin contents from `round-03.json`. `--ids` lists pin ids in latest round.

### Task 6.1: stop-live.sh

- [ ] **Step 1: Write the failing test** `test_stop_live_kills_running_proxy`. Spawn `live.sh` in a subprocess, wait until PID file appears, run `stop-live.sh`, assert PID file removed and the proxy process is gone within 2s.
- [ ] **Step 2: Run test to verify it fails.**
- [ ] **Step 3: Write `stop-live.sh`** — copy `stop.sh` structure verbatim, change `PID_FILE="${PWD}/.ui-forge/.live-server.pid"` and message strings to `[ui-forge] live`.
- [ ] **Step 4: Run test to verify it passes.** Commit.

### Task 6.2: status-live.sh

- [ ] **Step 1: Write the failing test** `test_status_live_reports_running_and_not_running`. Two subtests: with no PID file → output contains `not running`; with a running proxy → output contains `running` and `4270` and the PID.
- [ ] **Step 2: Run test to verify it fails.**
- [ ] **Step 3: Write `status-live.sh`** — copy `status.sh` structure, swap PID file path, swap port to 4270, swap label to `[ui-forge] live`.
- [ ] **Step 4: Run test to verify it passes.** Commit.

### Task 6.3: Clean shutdown — close WS + ClientSession

- [ ] **Step 1: Write the failing test** `test_sigterm_closes_active_ws_within_2s`. Spawn live.py via subprocess, open a WS connection through it, send SIGTERM to the proxy, assert (via stub upstream's connection tracker) the upstream WS closes within 2s and the proxy process exit code is 0.
- [ ] **Step 2: Run test to verify it fails** (current SIGTERM only removes PID, doesn't close active connections gracefully).
- [ ] **Step 3: In live.py:**
  - Track all active `ws_server` instances in an `asyncio.WeakSet` stored on the app.
  - In the SIGTERM handler, call `loop.create_task(_graceful_shutdown(app))`.
  - `_graceful_shutdown` closes the shared ClientSession, closes every active WS, then `runner.cleanup()` and `loop.stop()`.
  - Use `aiohttp.web.run_app(app, ...)` with the standard signal handling (it already handles SIGTERM/SIGINT to shutdown — verify and only add what's missing).
- [ ] **Step 4: Run test to verify it passes.** Commit.

### Task 6.4: show-pin-live.py

- [ ] **Step 1: Write the failing test** `test_show_pin_live_prints_pin_details`. Pre-populate `.ui-forge/live/s1/round-03.json` with two pins, run `python3 show-pin-live.py s1 --round 3 --pin 2`, assert stdout includes pin 2's comment and selector.
- [ ] **Step 2: Run test to verify it fails.**
- [ ] **Step 3: Adapt `show-pin.py`** into `show-pin-live.py`:
  - Positional arg becomes `session_id` instead of `screen_id`.
  - Path becomes `.ui-forge/live/{session_id}/round-{round:02d}.json` instead of `.ui-forge/screens/{screen_id}/feedback/round-{round:02d}.json`.
  - Default `--round` is the round in `latest.json` for that session.
  - Same `--ids`, `--pin`, `--json` flags.
- [ ] **Step 4: Add a `--list-sessions` flag** that lists the directories under `.ui-forge/live/` with their latest round and timestamp.
- [ ] **Step 5: Run test to verify it passes.** Commit.

**Wave 6 rollback note:** All new files in `scripts/live/` + clean shutdown wiring in `live.py`. No external files touched.

---

## Wave 7: overlay.js live branch

**Deliverable:** `overlay.js` recognises `window.UIFORGE_MODE === 'live'` and switches to live behavior: storage key keyed on host+session, payload shape includes mode/sessionId/host/path, scenario UI hidden, SSE auto-reload disabled (HMR handles reload). Prototype branch unchanged.

**Files to modify:**
- `plugins/forge-ui-forge/skills/ui-forge/assets/overlay.js`

**Files to create:**
- `plugins/forge-ui-forge/tests/live/test_overlay_live_branch.py` (uses Python's headless DOM via subprocess `node` if available, OR inline JS evaluated through `aiohttp` end-to-end test — see Task 7.1)

**Acceptance criteria:**
- When `UIFORGE_MODE === 'live'`, `STORAGE_KEY` evaluates to `uiforge:live:<host>:pins`.
- Payload sent to `/forge/feedback` includes `mode: 'live'`, `sessionId`, `host`, `path` and does NOT include `screen` or `scenario`.
- Scenario selector DOM is not rendered in live mode.
- `EventSource('/forge/reload')` is NOT created in live mode.
- All existing prototype-mode behaviors still work (regression test by loading a prototype `02-forge.html` and verifying the FAB renders).

### Task 7.1: Test harness for overlay.js (end-to-end via proxy)

- [ ] **Step 1: Decide test harness.** Two options:
  - **A.** Spin up the live proxy + a stub upstream returning a small HTML, then use `aiohttp` to GET it and parse the injected HTML; verify the init payload values. For overlay behavior, eval JS via Python is hard — defer to manual smoke test.
  - **B.** Add a Python test that imports `js2py` or invokes `node -e` with the overlay.js source and a stub `window` object; assert the `STORAGE_KEY` value.
  - **Recommendation: A for the integration, plus a tiny Node-based unit test for the JS branch logic** (`node -e` is universally available; no extra Python deps).
- [ ] **Step 2: Write `test_overlay_live_branch.py`** with two test functions: `test_storage_key_in_live_mode` and `test_payload_shape_in_live_mode`. Both invoke `subprocess.run(['node', '-e', SCRIPT])`. SCRIPT loads overlay.js with a fake `window` (`{ UIFORGE_MODE: 'live', UIFORGE_LIVE_HOST: 'localhost:3000', UIFORGE_SESSION_ID: 's1', localStorage: stub, ... }`), then console.logs the computed STORAGE_KEY and a sample buildPayload. Skip if `node` not in PATH.
- [ ] **Step 3: Verify test infrastructure works** with a placeholder assertion (will fail until Wave 7.2 implements the branch). Commit.

### Task 7.2: Live branch — STORAGE_KEY and constants

**File:** `plugins/forge-ui-forge/skills/ui-forge/assets/overlay.js`

- [ ] **Step 1: Run `test_storage_key_in_live_mode` to confirm it fails.**
- [ ] **Step 2: Add at the top of the IIFE** (after the `'use strict'`):
  ```js
  const IS_LIVE = window.UIFORGE_MODE === 'live';
  const LIVE_HOST = window.UIFORGE_LIVE_HOST || 'unknown-host';
  const LIVE_SESSION = window.UIFORGE_SESSION_ID || 'unknown-session';
  const KEY_BASE = IS_LIVE
    ? `uiforge:live:${LIVE_HOST}`
    : `uiforge:${window.UIFORGE_SCREEN_ID || 'unknown'}`;
  const STORAGE_KEY = `${KEY_BASE}:pins`;
  const SCENARIO_KEY = `${KEY_BASE}:scenario`;
  const FILTER_KEY = `${KEY_BASE}:round-filter`;
  ```
  Replace the existing 4 lines defining these constants. Prototype branch unchanged because `IS_LIVE` is false in that case.
- [ ] **Step 3: Run test to verify it passes.** Commit.

### Task 7.3: Live branch — payload shape

- [ ] **Step 1: Run `test_payload_shape_in_live_mode` to confirm it fails.**
- [ ] **Step 2: Modify `buildPayload(round)`** to branch on `IS_LIVE`:
  ```js
  function buildPayload(round) {
    var newPins = pins.filter(function(p) { return !p.sentInRound; });
    var common = {
      round: round,
      exportedAt: new Date().toISOString(),
      pinCount: pins.length,
      newPinCount: newPins.length,
      newPinIds: newPins.map(function(p) { return p.id; }),
      pins: pins,
    };
    if (IS_LIVE) {
      return Object.assign(common, {
        mode: 'live',
        sessionId: LIVE_SESSION,
        host: LIVE_HOST,
        path: window.UIFORGE_LIVE_PATH || location.pathname,
      });
    }
    return Object.assign(common, {
      screen: window.UIFORGE_SCREEN_ID,
      scenario: currentScenario,
    });
  }
  ```
- [ ] **Step 3: Run test to verify it passes.** Commit.

### Task 7.4: Live branch — skip scenario UI

- [ ] **Step 1: Identify all DOM creations for the scenario selector** (search `UIFORGE_SCENARIOS` references in overlay.js). Currently around line 434.
- [ ] **Step 2: Wrap the scenario UI creation** in `if (!IS_LIVE) { ... }`.
- [ ] **Step 3: Wrap `applyScenario()` call sites** to be no-ops when `IS_LIVE` (live mode has no `window.render` and no `UIFORGE_DATA`).
- [ ] **Step 4: Manual smoke test** — open a prototype 02-forge.html, scenario selector still appears. (No automated test; a one-line confirmation in the commit message.)
- [ ] **Step 5: Commit.**

### Task 7.5: Live branch — skip SSE auto-reload

- [ ] **Step 1: Modify `setupSSE`:**
  ```js
  function setupSSE() {
    if (!IS_SERVED || IS_LIVE) return;
    // ... existing code
  }
  ```
  Comment: HMR in the host app handles reloads; the proxy doesn't watch any files.
- [ ] **Step 2: Manual smoke test** — load a stub HTML through the proxy, verify no `/forge/reload` request appears in the proxy logs.
- [ ] **Step 3: Commit.**

### Task 7.6: Regression — prototype mode still works

- [ ] **Step 1: Run the existing prototype-mode flow manually.**
  - Pick a temp directory, run `init-registry.sh`, drop a minimal `02-forge.html`, run `serve.sh`, open in browser, click annotate, click 🚀.
  - Verify pin appears in `.ui-forge/screens/<id>/feedback/round-01.json`.
- [ ] **Step 2: If anything broke**, fix in this wave (root cause must be in the Wave 7 changes, since earlier waves only touched live/ files).
- [ ] **Step 3: Commit.**

**Wave 7 rollback note:** All overlay.js changes are additive branches. Reverting the commit removes the `IS_LIVE` constant and the conditional branches; the file falls back to its previous behavior verbatim.

---

## Wave 8: Documentation, version bump, marketplace entry

**Deliverable:** SKILL.md describes live mode in a markered section. `references/subcommands.md` documents `live`, `stop-live`, `status-live`. `plugin.json` and `marketplace.json` bumped to 0.4.0. Single squashed commit.

**Files to modify:**
- `plugins/forge-ui-forge/skills/ui-forge/SKILL.md`
- `plugins/forge-ui-forge/skills/ui-forge/references/subcommands.md`
- `plugins/forge-ui-forge/.claude-plugin/plugin.json`
- `.claude-plugin/marketplace.json`

**Acceptance criteria:**
- `SKILL.md` contains a section bracketed by `<!-- ui-forge:live:start -->` and `<!-- ui-forge:live:end -->` describing when to use live mode, how to start it, where pins land, and that it requires `pip install aiohttp`.
- `SKILL.md` Subcommands table has 3 new rows.
- `subcommands.md` has `## live`, `## stop-live`, `## status-live` sections with exact bash snippets.
- `plugin.json` version is `0.4.0`.
- `marketplace.json` `forge-ui-forge` entry is `0.4.0` and the description mentions live mode.
- `python3 -m json.tool < .claude-plugin/marketplace.json` succeeds.
- `python3 -m json.tool < plugins/forge-ui-forge/.claude-plugin/plugin.json` succeeds.
- The CLAUDE.md sync rule from `.claude/rules/sync-keeps-docs-current.md` passes a manual check (count parity between marketplace and README — README mentions ui-forge once with no version, so no edit needed there).

### Task 8.1: SKILL.md live section

- [ ] **Step 1: Add markered section after the existing "Subcommands" section** in SKILL.md:
  ```markdown
  <!-- ui-forge:live:start -->

  ## Live mode (overlay over an existing dev server)

  Use when you want to annotate the **real running application** (Vite/Next/Rails/Django/anything HTTP) the same way you annotate prototypes — without modifying the app's source. The live proxy sits in front of your dev server, injects `overlay.js` into HTML responses, and collects pins in `.ui-forge/live/<session-id>/`.

  **Requires `aiohttp`** — install once with `pip install aiohttp`. Prototype mode keeps working without it.

  **What it is NOT (v1):** Claude does **not** auto-edit `src/` from live-mode pins. Pins land as JSON; you decide when and how to apply them. (Auto-apply is a v2 follow-up.)

  ### Starting

  ```
  Monitor: bash "${CLAUDE_PLUGIN_ROOT}/skills/ui-forge/scripts/live/live.sh" --target http://localhost:3000
  ```

  Optional flags:
  - `--port 4270` (default — coexists with prototype server on 4269)
  - `--name <slug>` (default: ISO timestamp; sets the directory name under `.ui-forge/live/`)

  Open `http://127.0.0.1:4270` in the browser. Your app loads identically (HMR included) plus the overlay FAB.

  ### Feedback flow

  1. User annotates → clicks 🚀.
  2. Monitor delivers `[ui-forge] live round=N session=<id> host=<host> path=<path> ...`.
  3. Read `.ui-forge/live/<session-id>/latest.json` → get the round filename.
  4. Read the round JSON → decide what to do (edit `src/`, refine spec, plan a change). The skill is a feedback collector; the action is yours.

  ### Limitations (v1)

  - Upstream must be **HTTP** (no HTTPS upstream targets in v1).
  - One target per `live` invocation. Run multiple proxies on different ports for multiple targets.
  - Authentication is forwarded as `aiohttp.ClientSession` does by default (cookies, auth headers). Custom auth proxies are out of scope.

  <!-- ui-forge:live:end -->
  ```
- [ ] **Step 2: Add 3 rows to the Subcommands table:**
  ```markdown
  | `live`        | Start live proxy under Monitor. Requires `pip install aiohttp`. Prints clickable URL. |
  | `stop-live`   | Kill live proxy by PID from `.ui-forge/.live-server.pid`. |
  | `status-live` | Check if live proxy is running. |
  ```
- [ ] **Step 3: Verify markers are exact** (`grep -c 'ui-forge:live:start' SKILL.md` returns 1, same for end). Commit.

### Task 8.2: subcommands.md live entries

- [ ] **Step 1: Append three sections at end of `references/subcommands.md`:**
  - `## live` — bash snippet, explanation of `--target`/`--port`/`--name`, the startup line format, the URLs the user should open.
  - `### On feedback event (live mode)` — the live-mode stdout line format and example, and how to use `show-pin-live.py`.
  - `## stop-live` — bash snippet, output format.
  - `## status-live` — bash snippet, output format.
- [ ] **Step 2: Verify content is consistent with what live.py actually prints** by re-reading both. Commit.

### Task 8.3: Version bump

- [ ] **Step 1: Edit `plugins/forge-ui-forge/.claude-plugin/plugin.json`** — change `"version": "0.3.0"` to `"version": "0.4.0"`.
- [ ] **Step 2: Edit `.claude-plugin/marketplace.json`** — find `forge-ui-forge` entry, change version `0.3.0` → `0.4.0`. Append `, plus live mode that proxies an existing dev server and injects the overlay (opt-in, requires aiohttp)` to the description.
- [ ] **Step 3: Validate JSON** — `python3 -m json.tool < plugins/forge-ui-forge/.claude-plugin/plugin.json && python3 -m json.tool < .claude-plugin/marketplace.json`.
- [ ] **Step 4: Sync check** — manual: read CLAUDE.md tree, confirm forge-ui-forge appears (it does, line `forge-ui-forge/` under "UI prototyping"); read README.md plugin tables for ui-forge entry, confirm count matches marketplace (no version-pinning in README, so nothing to edit). Commit.

### Task 8.4: Squash commits + final verification

- [ ] **Step 1: Run all live tests** — `python3 -m pytest plugins/forge-ui-forge/tests/live/ -v`. All green.
- [ ] **Step 2: Smoke-test prototype mode end-to-end** one more time — `serve.sh` + a synthetic `02-forge.html` + click 🚀 → round file written.
- [ ] **Step 3: Smoke-test live mode end-to-end** with a tiny stub HTTP server (`python3 -m http.server 3000` serving an `index.html` that contains `<html><body><div id="app">hello</div></body></html>`):
  - Run `live.sh --target http://localhost:3000`.
  - Open `http://127.0.0.1:4270`, view source, confirm the injected `<script>` block is present.
  - Run `curl http://127.0.0.1:4270/forge/__overlay.js | head -1` — confirm overlay.js is served.
  - POST a fake feedback payload via curl — confirm `.ui-forge/live/<session-id>/round-01.json` appears.
- [ ] **Step 4: Squash all wave commits** into one with message:
  ```
  feat(ui-forge): live overlay proxy mode

  Adds `live`, `stop-live`, `status-live` subcommands that proxy an
  existing dev server (any stack) on port 4270, inject overlay.js into
  HTML responses, and collect pins into .ui-forge/live/<session-id>/.

  - New files isolated to scripts/live/ + tests/live/
  - SKILL.md changes wrapped in <!-- ui-forge:live:start/end --> markers
  - overlay.js changes are additive branches gated by UIFORGE_MODE
  - Optional dependency: aiohttp (preflighted by live.sh)
  - Prototype mode (serve.py / serve.sh) untouched

  Rollback: `git revert <this-sha>` — removes live mode in full,
  prototype mode keeps working without intervention.

  Plugin version: 0.3.0 → 0.4.0.
  ```
- [ ] **Step 5: Push branch, open PR with the same body. DO NOT merge until user approves.**

**Wave 8 rollback note:** A clean `git revert` undoes the version bump, marketplace entry edit, SKILL.md and subcommands.md additions, and removes everything in `scripts/live/` and `tests/live/`. Verify by running prototype-mode smoke test post-revert.

---

## Test strategy summary

Every functional requirement maps to at least one automated test:

| Requirement | Wave | Test file |
|---|---|---|
| HTTP request/response passthrough | 1 | `test_http_passthrough.py` |
| HTML injection at right point | 2 | `test_html_injection.py` |
| Idempotent injection | 2 | `test_html_injection.py` |
| Static endpoints (overlay.js) | 3 | `test_static_endpoints.py` |
| WebSocket upgrade + bidirectional pump | 4 | `test_websocket_proxy.py` |
| Feedback POST writes JSON files | 5 | `test_feedback_intercept.py` |
| Stdout trigger format | 5 | `test_feedback_intercept.py` |
| Preflight on missing aiohttp | 1 | `test_preflight.py` |
| Clean shutdown of background tasks on signals | 6 | `test_shutdown.py` |
| Overlay live branch (storage key, payload) | 7 | `test_overlay_live_branch.py` |

**Manual smoke tests** (executed at end of Waves 1, 4, 5, 6, 7, 8):
- Prototype mode (`serve.sh` + 02-forge.html + click 🚀) still works.

**End-to-end manual (Wave 8.3):**
- Live proxy in front of `python3 -m http.server` returning a stub HTML — overlay loads, feedback POST writes a file.

---

## Self-review

**Spec coverage:**
- ✅ HTTP+WS proxy on separate port
- ✅ Inject overlay into HTML, leave non-HTML alone
- ✅ Specify target at startup
- ✅ Pins to `.ui-forge/live/<session-id>/round-NN.json`
- ✅ aiohttp optional, preflight on missing
- ✅ Strict file isolation under `scripts/live/`
- ✅ SKILL.md markers
- ✅ overlay.js gated by UIFORGE_MODE
- ✅ Single commit, version bump 0.3 → 0.4
- ✅ Subcommands `live`, `stop-live`, `status-live`
- ✅ Default port 4270
- ✅ Default session-id = ISO timestamp, override with `--name`
- ✅ Stdout trigger format with mode=live, host, path
- ✅ Open question answered: option (a) feedback collector only, (b) deferred to v2
- ✅ Test strategy covers all 6 listed concerns
- ✅ Out-of-scope items not present in any task: no auto-edit of src/, no multi-target, no HTTPS upstream, no custom auth

**Placeholder scan:** none.

**Type/name consistency:**
- `session_id` (snake_case) in Python, `sessionId` (camelCase) in JSON payloads and JavaScript — consistent across all references.
- `UIFORGE_MODE` constant is consistent: 'live' (lowercase) in both JS check and Python injection.
- PID file path `.ui-forge/.live-server.pid` is identical in `live.py`, `stop-live.sh`, `status-live.sh`.
- Port 4270 is referenced in `live.py` default, `status-live.sh` startup line, and SKILL.md.
- Markers `<!-- ui-forge:live:start -->` / `<!-- ui-forge:live:end -->` are identical in SKILL.md task and in the rollback contract.
- Markers `<!-- ui-forge:live:injected:start -->` / `<!-- ui-forge:live:injected:end -->` (response injection) are distinct from the SKILL.md markers — intentional, no collision.

**Plan boundary:** stops before any v2 work (auto-apply pins to src/, multi-target, HTTPS, auth proxy). Recorded as follow-ups in Wave 8 SKILL.md.

---

## Execution handoff

**1. Subagent-Driven (recommended)** — Use `forge-superpowers:subagent-driven-development` or `forge-executor:execute-plan`. Each wave runs in a fresh subagent with TDD enforcement, and the user reviews the wave commit before moving on. Best for this plan because each wave is self-contained and testable.

**2. Inline Execution** — Use `forge-superpowers:executing-plans`. Run the plan in the current session step-by-step. Faster for one-shot execution but loses the per-wave review checkpoint.

**Recommendation: option 1 with `forge-executor:execute-plan`** so the validation gates (per-wave acceptance criteria + smoke tests) are enforced automatically and you can rollback per wave if anything goes sideways.
