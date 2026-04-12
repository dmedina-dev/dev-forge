# Operational notes — full reference

Gotchas, config details, and lifecycle caveats. SKILL.md has a two-line
summary; this is the long form.

## Sandbox gotcha — runaway duplicate events

**Symptom.** You run `/telegram start` successfully. The first inbound
message arrives and is handled correctly. Then the session starts
rendering a flood of the same event over and over (or "Monitor event"
headers with no content) — one every ~0.2 seconds. The listener never
advances past that first message.

**Root cause.** Claude Code's Bash sandbox blocks writes to paths outside
the current project root. `listen.sh` stores its Telegram long-poll
offset at `~/.claude/channels/telegram/.offset`, which is **outside any
project**. Under the sandbox, every write to that file returns `rc=1`
silently — `listen.sh` uses `set -uo pipefail` (not `-e`) so the failure
doesn't abort the loop. The result: the offset never advances, Telegram
returns the same update every poll, the script re-emits the same event
forever.

**Diagnosis.** Run the listener once (it'll pre-flight and tell you if
the sandbox is blocking writes). Or manually:

```bash
echo 12345 > ~/.claude/channels/telegram/.offset; echo "rc=$?"
cat ~/.claude/channels/telegram/.offset
```

If `rc=0` and the readback is `12345`, the sandbox is NOT the problem.
If `rc=1` or the readback differs, you're being sandboxed.

**Fix A — sandbox allowlist (recommended).** Add this to the project's
`.claude/settings.local.json`. If a `sandbox.filesystem.allowWrite`
list already exists, **merge** — don't replace:

```json
{
  "sandbox": {
    "filesystem": {
      "allowWrite": [
        "~/.claude/channels/telegram/.env",
        "~/.claude/channels/telegram/.offset",
        "~/.claude/channels/telegram/.pairing-offset",
        "~/.claude/channels/telegram/mode",
        "~/.claude/channels/telegram/listen.log",
        "~/.claude/channels/telegram/emit.log",
        "~/.claude/channels/telegram/inbox/",
        "~/.claude/channels/telegram/menu.json"
      ]
    }
  }
}
```

Each entry matches exactly the write surface of `listen.sh` + `setup.sh` + `mode.sh`:

| Path | Written by | Purpose |
|---|---|---|
| `.env` | `setup.sh` | Bot token, chat id, optional OpenAI key |
| `.offset` | `listen.sh` | Telegram long-poll cursor — **this is the one that causes the runaway when blocked** |
| `.pairing-offset` | `setup.sh` | Short-lived offset during PIN pairing |
| `mode` | `mode.sh` | Current response mode (`strict` / `conversational` / `trust`), read on `/telegram start` |
| `listen.log` | `listen.sh` | Diagnostic log (curl errors, emit refusals, unsupported messages) |
| `emit.log` | `listen.sh` | Timestamped mirror of every JSON event sent to stdout |
| `inbox/` | `listen.sh` | Downloaded inbound photos, one file per message |
| `menu.json` | `menu.sh` | Custom Telegram `/` command menu (optional, overrides defaults) |

**Syntax variants** if the `~/` form isn't accepted by your Claude Code
version: try the absolute form (`/Users/you/.claude/channels/telegram/…`)
or whatever relative-to-home notation the `excludedCommands` section of
your existing sandbox config uses as reference.

**Fix B — TELEGRAM_STATE_DIR override.** If you can't edit the sandbox
config (shared settings, org policy, etc.), move the plugin's state
into the project root so it's naturally inside the sandbox. Before
starting:

```bash
export TELEGRAM_STATE_DIR="$PWD/.telegram-state"
mkdir -p "$TELEGRAM_STATE_DIR" && chmod 700 "$TELEGRAM_STATE_DIR"
/telegram setup   # re-pairs, writes .env in the new location
/telegram start
```

This trades one annoyance for another: the state dir is now per-project
instead of per-user, so re-pairing is required when you switch projects.

**Fix C — disable the sandbox for the session.** In
`.claude/settings.local.json`:

```json
{ "sandbox": { "enabled": false } }
```

Use only if you don't otherwise rely on the sandbox for safety.

---

## Setup and start are mutually exclusive

**Do not run `/telegram setup` while `/telegram start` is active.** The pairing flow uses a dedicated `.pairing-offset` file so it does not corrupt the listener's `.offset`, but pairing only runs when `AUTHORIZED_CHAT_ID` is missing — which is exactly when `/telegram start` refuses to spawn. Still, keep them sequential to avoid confusion.

## Credentials location

**`~/.claude/channels/telegram/.env`** (chmod 0600). This is user-level config, not project-level. Running `/telegram setup` once per machine is enough — it persists across projects and sessions. The file contains:

- `TELEGRAM_BOT_TOKEN` — the bot token from BotFather
- `AUTHORIZED_CHAT_ID` — the paired chat (single user model)
- `OPENAI_API_KEY` — optional, enables Whisper voice transcription

## Voice transcription

**Optional.** If the user skipped `OPENAI_API_KEY` during setup, voice messages arrive as `"[voice message received — OPENAI_API_KEY not set]"`. They can run `/telegram setup` again to add the key later. With the key set, voice messages are transcribed inline by `transcribe.sh` before `listen.sh` emits the event.

## macOS line buffering

**macOS requires `brew install coreutils`** for the `gstdbuf` binary used by `listen.sh` for line-buffered output. Without it the listener will still work but events may be delayed until the pipe buffer fills.

## Listener lifecycle — per-session only

**The listener dies with the session.** `Monitor(persistent: true)` keeps `listen.sh` alive until the session ends (or until `/telegram stop` is called). There is no cross-session listener, and no re-arm loop — each new session that wants Telegram inbound must run `/telegram start` itself.

## Telegram `/` menu commands

`setup.sh` registers a slash-commands menu via `setMyCommands` so the Telegram chat shows autocomplete suggestions when the user taps `/`.

### Built-in commands (always present)

Three commands are **always registered** and **always executed** from Telegram regardless of the current response mode. They are the only Telegram text that bypasses strict mode:

| Command | Behaviour |
|---------|-----------|
| `/stop` | Asks for confirmation via reply, then stops the listener on second `/stop`. |
| `/qa` | Runs the project's QA pipeline (lint + test + build). Replies with per-phase results. |
| `/status` | Reports current tasks, mode, branch, and active background work. |

These built-in commands cannot be removed or overridden by custom menus. They are appended at the end of whatever menu is registered.

### Custom commands

Projects can add their own commands via `/telegram menu set <file.json>`. The JSON format:

```json
[
  {"command": "tests", "description": "Run full test suite"},
  {"command": "git",   "description": "Branch + status + recent commits"},
  {"command": "help",  "description": "List available commands"}
]
```

Custom commands are **cosmetic only** — they appear in Telegram's autocomplete, but the text arrives at `listen.sh` as an ordinary message. The assistant decides what to do with them based on the current mode (they are NOT auto-executed like built-ins). To define behaviour for custom commands, use project-level memory or CLAUDE.md instructions (see the stock-manager pattern).

The custom menu is stored at `~/.claude/channels/telegram/menu.json`. Both `setup.sh` and `/telegram menu register` read this file — **custom menus survive `setup` re-runs.**

If a custom menu entry uses the same name as a built-in (`stop`, `qa`, `status`), the built-in version takes precedence.

To remove custom commands (keep only built-ins): `/telegram menu reset`.

Since `setMyCommands` is bot-scoped (not chat-scoped), the last project to register wins. If you use one bot across multiple projects, the menu reflects whichever project called `menu set` last.

## Inbound photo inbox

**`~/.claude/channels/telegram/inbox/`.** `listen.sh` downloads the largest size variant of each inbound photo to that directory on arrival and emits the absolute path in the event's `image_path` field.

**Old files are never cleaned up automatically.** Run `rm -rf ~/.claude/channels/telegram/inbox/*` periodically if the directory grows. Telegram compresses photos; if the user needs the original resolution, they should send the file as a document (long-press → Send as File), but documents are not yet supported by this plugin and will log as "unsupported message type".
