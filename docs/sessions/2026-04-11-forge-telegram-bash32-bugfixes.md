# forge-telegram — macOS bash 3.2 bugfix pass — 2026-04-11

## Summary

`forge-telegram` v1.0.0 was unusable on macOS system bash (3.2.57) out of the box. Fresh install → `/telegram setup` dies silently before printing anything; if bypassed, setup appears to succeed but never writes `AUTHORIZED_CHAT_ID`; if that is then bypassed, `/telegram start` brings up the listener which crashes on the first inbound message and gives up after 3 restarts.

Three bugs, two root causes, all in `plugins/forge-telegram/scripts/`. Validated end-to-end on macOS 25.4.0 / bash 3.2.57 / arm64 by running through the full flow: pair → listen → receive real Telegram message → appear in parent session with no crash.

Bumped plugin version `1.0.0 → 1.0.1`.

## Bugs

### Bug 1 — `setup.sh` aborts silently before the PIN banner

**Where:** `scripts/setup.sh:38` (`get_env_key` helper) + `:61-63` (first callers).

**Why:** Script uses `set -euo pipefail`. The helper is `grep | head | cut`. When the requested key is not yet in `.env` (first run, or after saving the token on a re-run), `grep` exits 1, `pipefail` propagates it, `set -e` aborts **at the variable assignment on line 62** — before any `echo` or `read` runs. On bash 3.2 the user sees zero output.

**Fix:** make `get_env_key` tolerate the no-match path:

```diff
 get_env_key() {
-  grep -E "^$1=" "$ENV_FILE" 2>/dev/null | head -1 | cut -d= -f2-
+  { grep -E "^$1=" "$ENV_FILE" 2>/dev/null || true; } | head -1 | cut -d= -f2-
 }
```

No behavior change on Linux or Homebrew bash 5.x where the original happened to not abort under some conditions.

### Bug 2 — `setup.sh` assigns to readonly `UID` in the PIN pairing loop

**Where:** `scripts/setup.sh:177`.

**Why:** `UID` is a **readonly** shell variable in bash (it holds the real user id, e.g. `501`). `UID=$(echo "$UPDATE" | jq '.update_id')` fails with `UID: readonly variable`. Under `set -e` this aborts the pairing loop → user sees the PIN, sends it, nothing happens. Without `set -e`, execution continues but the next line `echo "$((UID + 1))" > "$PAIRING_OFFSET_FILE"` writes `502` (real uid + 1) as a Telegram update offset, corrupting the poll. Sometimes the script still reaches the success banner while `AUTHORIZED_CHAT_ID` was never written — false positive.

**Fix:** rename the loop-local to anything that is not a bash builtin:

```diff
 while IFS= read -r UPDATE; do
-  UID=$(echo "$UPDATE" | jq '.update_id')
-  echo "$((UID + 1))" > "$PAIRING_OFFSET_FILE"
+  # NOTE: use UPD_ID, not UID — $UID is a readonly builtin in bash (real uid)
+  UPD_ID=$(echo "$UPDATE" | jq '.update_id')
+  echo "$((UPD_ID + 1))" > "$PAIRING_OFFSET_FILE"
```

### Bug 3 — `listen.sh` has the same readonly-`UID` bug in its hot path

**Where:** `scripts/listen.sh:103`.

**Why:** Same pattern as Bug 2, this time in the long-poll update-iteration loop. Every single inbound Telegram message hits this line. `listen.sh` only sets `set -uo pipefail` (no `-e`), but the readonly failure still ends up terminating the process once it interacts with arithmetic expansion and a write redirection in the same statement. The `telegram-listener` teammate observes the exit, logs `listener crashed, restarting`, re-arms — until hitting its 3-failure threshold and giving up with `giving up after 3 consecutive failures — run /telegram status to debug`.

From the user's perspective this is indistinguishable from a network problem, because the offending message is never logged: the child process dies before anything gets written to `listen.log`.

**Fix:** identical rename, different file:

```diff
 while IFS= read -r UPDATE; do
-  UID=$(echo "$UPDATE" | jq '.update_id')
-  echo "$((UID + 1))" > "$OFFSET_FILE"
+  # NOTE: use UPD_ID, not UID — $UID is a readonly builtin in bash (real uid)
+  UPD_ID=$(echo "$UPDATE" | jq '.update_id')
+  echo "$((UPD_ID + 1))" > "$OFFSET_FILE"
```

## Why a Linux-only CI would have missed this

- **Bug 1** only manifests on bash 3.2 + `pipefail`. On bash 4.4+ (every mainstream Linux) `set -e` has slightly different behavior around command substitutions inside variable assignments, and the specific aborting path does not trigger. The script runs through.
- **Bugs 2 and 3** manifest on **every** bash version where `UID` is readonly — which is all of them — but only on a real PIN pairing / inbound message, not on a `bash -n` syntax check, and the failure modes under `set -e` vs not are different enough that a "happy-path CI" that never sends a real Telegram message would silently pass.

Any bash with a shellcheck step would have caught Bugs 2 and 3 (SC2034 / SC3028-family). Bug 1 needs an actual run on macOS bash 3.2.

## Suggested regression guard

Add to plugin-level tests:

```bash
# scripts/ must not assign to readonly bash builtins
if grep -nE '^\s*(UID|EUID|PPID|GROUPS|FUNCNAME|BASHPID|LINENO)=\$' \
     plugins/forge-telegram/scripts/*.sh; then
  echo "error: assignment to readonly bash builtin in forge-telegram scripts"
  exit 1
fi
```

A full dry run of `setup.sh` against an empty `HOME` with stdin closed is enough to catch Bug 1:

```bash
HOME=$(mktemp -d) /bin/bash plugins/forge-telegram/scripts/setup.sh <<< '' &
SETUP_PID=$!
sleep 2
kill -0 "$SETUP_PID" || { echo "FAIL: setup.sh died before PIN banner"; exit 1; }
kill "$SETUP_PID" 2>/dev/null || true
```

## Validation evidence

- Environment: macOS Darwin 25.4.0 (arm64), `/bin/bash` 3.2.57, `curl` 8.x, `jq` 1.7, `gstdbuf` **not** installed (optional), plugin installed as user-scope.
- Reset `~/.claude/channels/telegram/.env`, ran patched `setup.sh`, received PIN `567266`, sent it from phone → pairing completed, `AUTHORIZED_CHAT_ID` written to `.env`.
- `/telegram start` → listener online.
- Sent `"Ahora si?"` from phone → appeared in the parent session as a single event, no crash, no auto-restart.
- After fix, `listen.sh` ran 8 s standalone with no errors; offset advanced correctly to the real Telegram `update_id` (observed value around `853272877`).

## Files changed

- `plugins/forge-telegram/scripts/setup.sh` — Bugs 1 + 2 (committed earlier in `519438d fix(forge-telegram): bash 3.2 setup.sh aborts on pipefail + readonly UID`)
- `plugins/forge-telegram/scripts/listen.sh` — Bug 3 (this commit)
- `plugins/forge-telegram/.claude-plugin/plugin.json` — version bump `1.0.0 → 1.0.1`
- `docs/sessions/2026-04-11-forge-telegram-bash32-bugfixes.md` — this file
