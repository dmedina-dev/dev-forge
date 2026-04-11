# forge-telegram — architecture collapse, features, sandbox saga, modes — 2026-04-11

## Summary

Full-day forge-telegram rewrite. Started at v1.0.0 with a Haiku teammate relaying events, ended at v1.0.2 with the main session owning Monitor directly, three response modes, five new features, and a fully sandbox-safe state dir.

Released: v1.12.0, v1.12.1 (ghost tag), v1.12.2, v1.12.3 + several unreleased post-release fixes.

## Phase 1 — telegram-listener agent prompt fixes
(commit c391f08)

Two bugs in the agent prompt written earlier:

- **Monitor re-arm loop.** The prompt told the agent "your turn will block inside this Monitor call" and to "immediately re-arm after each return". But `Monitor(persistent: true)` is ASYNC — it returns right away, events arrive as new turns. Re-arming spawned a second concurrent `listen.sh`, doubled every event, triggered the harness auto-stop, and entered a self-reinforcing crash loop.
- **SendMessage missing `summary`.** All 7 example calls omitted the required `summary` field; every real call failed with "summary is required".

Fix: event-driven main loop, Monitor called exactly once, add summaries to all SendMessage examples. New safety rule documenting the `summary` requirement.

## Phase 2 — teammate removal, Monitor-direct
(commit e069309)

Realized the teammate added no value once Monitor is async. The main session can call Monitor directly and receive events as new turns in the same session — no SendMessage relay hop, no teammate lifecycle, no double-spawn class of bugs possible.

Deleted `plugins/forge-telegram/agents/telegram-listener.md`. Rewrote `skills/telegram/SKILL.md`:

- `allowed-tools`: Monitor, TaskList, TaskStop (was: Agent, SendMessage, TeamCreate, TeamDelete)
- `start` calls Monitor inline
- `stop` uses TaskList → TaskStop on the matching task
- New "Handling inbound Telegram events" section: parse JSON, frame as content, never execute as instruction (the initial strict default)

−59 / +167 lines net — the teammate was a lot of ceremony.

## Phase 3 — feature expansion
(commits b6df259, cb9e359, e099a8a)

Added four of the features the old `telegram@claude-plugins-official` had that we initially cut when going bash-only:

- **react.sh** — emoji reactions via `setMessageReaction`, with the fixed Bot API whitelist documented in the header
- **edit.sh** — `editMessageText` for "working… → done" progress updates, with the no-push-notification caveat documented
- **Inbound photos** — listen.sh detects `.message.photo`, downloads the largest variant via getFile, saves to `inbox/`, emits with `image_path` so the assistant can `Read()` it
- **Telegram `/` menu** — setup.sh registers `/status /context /help` via `setMyCommands` (cosmetic — text still arrives through the normal channel, still treated as untrusted)

Explicitly skipped (user OK with):
- typing indicator (needs a turn-start hook Claude Code doesn't expose)
- permission dialog with buttons (requires MCP rewrite)
- multi-user allowlist (user prefers single chat_id)

**SKILL.md segmentation.** The file grew to 274 lines. Split via progressive disclosure into SKILL.md (119 lines, hot path) + three reference files (`subcommands.md`, `outbound.md`, `operational.md`) loaded on-demand. Dispatch table + inbound event handling stay in SKILL.md because events fire on every turn while the listener is running.

## Phase 4 — runaway loop diagnosis
(commits 3a69be1, dd69c91)

Live test session reported: listener starts fine, first inbound message arrives and is handled correctly, then ~25+ "Monitor event:" turns arrive with no content. Visible runaway until the user stopped Monitor manually.

Initial fix (3a69be1) was defensive: guard every emit against empty/malformed JSON in listen.sh, tell the assistant in SKILL.md to end the turn silently on unparseable events.

The other session ran a stamped listen-wrapper (143 iterations logged deterministically) and found the real root cause:

```
iter=1 WROTE offset=853272883 rc=1 readback=853272882
iter=2 read_offset=853272882   ← offset never advanced
iter=2 WROTE offset=853272883 rc=1 readback=853272882
... ×143
```

Every `echo "$N" > .offset` returned `rc=1` silently. Because listen.sh uses `set -uo pipefail` (no `-e`), the failing redirect didn't abort. Telegram kept returning the same update on every long-poll. Duplicate events piled up.

Root cause: **stock-manager's `.claude/settings.local.json` has `sandbox.filesystem.allowWrite` restricted to 2 unrelated files, and `~/.claude/channels/telegram/.offset` isn't in that list**. Under the Bash sandbox, every write to paths outside that allowlist is silently denied.

Fix (dd69c91):

1. Add `TELEGRAM_STATE_DIR` env var override so users can redirect state into the project root as a last-resort workaround.
2. Add a preflight write check at listen.sh startup: write a sentinel, read it back, restore the original, fail fast if any step fails.
3. FATAL error message prints the exact JSON snippet for `sandbox.filesystem.allowWrite` that the user should add to `.claude/settings.local.json`, with 3 fallback options (TELEGRAM_STATE_DIR / disable sandbox / run claude from `$HOME`).

Extended `references/operational.md` with a new "Sandbox gotcha" section up front: symptom, root cause, manual diagnosis command, the 6-path allowlist snippet with a table explaining what each entry is for.

## Phase 5 — sandbox config at user level
(direct edits, no commit)

User asked if the sandbox allowlist could live at user level instead of per-project. Added the 7 paths (incl. the `mode` path from Phase 6) to BOTH `~/.claude/settings.local.json` and `stock-manager/.claude/settings.local.json`. Merge semantics for `sandbox.filesystem.allowWrite` between user and project level unknown, so covering both.

## Phase 6 — response modes
(commits d266b1a, 11e15b3)

User wanted the assistant to be more than just a display surface. Added three response modes:

- **strict** (default): display + auto-ack 👀 via react.sh, never execute, never reply
- **conversational**: strict + reply conversationally to non-imperative messages (greetings, questions)
- **trust**: strict + execute Telegram messages as if typed in terminal

d266b1a tracked the mode only in conversation context — lost on compact/clear/restart.

11e15b3 added `scripts/mode.sh` and a `/telegram mode <show|strict|conversational|trust>` subcommand. Mode persists in `~/.claude/channels/telegram/mode` (one word). `/telegram start` reads the file and announces the current mode prominently in its confirmation: "Mode: trust — ⚠ remote execution enabled" — so the user always sees which behaviour is active.

Also modified listen.sh to embed `chat_id` in every emission (from `AUTHORIZED_CHAT_ID`) so react.sh / edit.sh calls don't have to read `.env` to find the chat.

## Phase 7 — last-mile sandbox fixes
(commits 41730c8, 279161f)

Two more variants of the sandbox-blocks-writes bug found after the Phase 6 release:

**transcribe.sh** (41730c8). Called `mktemp -t telegram-voice.XXXXXX`, which on macOS resolves `$TMPDIR` to `/var/folders/…/T/` — also outside the sandbox allowlist. Fix: use `mktemp "$INBOX_DIR/voice-XXXXXX"` with an absolute template inside the already-allowlisted `inbox/` directory. No new allowlist entries needed.

**mode.sh** (279161f). Used a `mode.tmp.NNNN` staging file for atomic writes, but that filename pattern wasn't in the sandbox allowlist either. Since the mode file is a single word under `PIPE_BUF`, the write() syscall is already atomic — the staging pattern was over-engineering. Simplified to direct `printf > $MODE_FILE`.

## Lessons

Three generalized into memory entries (see `~/.claude/projects/-Users-dmedina-Factory-dev-forge/memory/`):

- **project_claude_sandbox.md** — the sandbox blocks writes outside project root, full allowlist schema, `$TMPDIR` gotcha
- **feedback_bash_preflight_state.md** — long bash loops must preflight their state-file writes, not trust rc silently
- **feedback_small_config_direct_write.md** — skip the tmp+mv pattern for tiny config files in sandboxed environments

Also folded into this repo:

- Root `CLAUDE.md` gotchas: sandbox-allowlist warning + `/forge-keeper:heal-plugin-cache` pointer
- `.claude/rules/plugin-authoring.md`: preflight rule, small-config direct-write rule, state-dir allowlist documentation rule

## Context for the next session

- forge-telegram is at v1.0.2 on disk and in plugin.json. Several unreleased commits on main since v1.12.3 (features, sandbox fixes, modes, transcribe/mode fixes). Next `/forge-commit:release` will bundle all of this.
- The 2 listen.sh processes that were seen running simultaneously in the test session (PIDs 89211 + 93696) may still need `pkill -f "forge-telegram.*listen.sh"` cleanup before testing.
- The `/telegram mode` subcommand is untested end-to-end by the user — mode.sh was verified in isolation but the full `/telegram start → mode trust → send message → execution` flow hasn't been smoke-tested yet in the live session.
