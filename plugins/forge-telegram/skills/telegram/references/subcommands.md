# /telegram subcommands — full reference

Detailed behaviour for every subcommand of `/telegram`. SKILL.md has a
one-line index; read this file before executing any subcommand that needs
more than the one-liner.

## `start` (or no args)

1. **Precondition check** — read `~/.claude/channels/telegram/.env`. It must contain both `TELEGRAM_BOT_TOKEN` and `AUTHORIZED_CHAT_ID`. If either is missing:
   > "Not configured. Run `/telegram setup` first."
   Stop here.

2. **Already running?** — call `TaskList()`. If any task has a description containing `"Telegram inbound messages"`:
   > "Listener already running. Use `/telegram stop` first if you want to restart it."
   Stop here.

3. **Arm the listener** — call `Monitor` directly. Events from `listen.sh` will arrive as new turns in this same session:

   ```
   Monitor(
     command: "bash ${CLAUDE_PLUGIN_ROOT}/scripts/listen.sh",
     description: "Telegram inbound messages (long-poll, line-delimited JSON)",
     persistent: true
   )
   ```

   Monitor returns immediately after registering the background task. Do NOT call Monitor again in this turn. Do NOT poll. The harness will deliver each JSON event to you as a new turn.

4. **Read the current response mode**:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/scripts/mode.sh get
   ```
   Possible values: `strict` (default), `conversational`, `trust`. Store that string — you'll announce it in the next step and apply it to every inbound event until the user changes it.

5. **Confirm to user** with the mode prominently displayed:
   > "📡 Telegram listener started. **Mode: `<mode>`** — [brief description matching the mode, e.g. 'display + 👀 ack only' for strict, 'may reply conversationally' for conversational, 'remote execution enabled' for trust]. Change with `/telegram mode <strict|conversational|trust>`. Run `/telegram stop` to shut down."

   The mode line is the most important part of the confirmation — the user needs to see it immediately so they know whether the session will talk back to Telegram, execute commands from it, or stay silent.

## `stop`

1. Call `TaskList()` and find the task whose description contains `"Telegram inbound messages"`.

2. If no such task exists:
   > "Listener is not running."
   Stop.

3. Otherwise call `TaskStop(task_id: <that task's id>)`.

4. Confirm: `"🛑 Telegram listener stopped."`

## `setup`

Run the interactive setup script. The user will be prompted in terminal for
the bot token, OpenAI key, and will see a PIN banner for chat pairing.

1. **Safety guard** — call `TaskList()`. If any task matches `"Telegram inbound messages"`, refuse:
   > "Stop the listener first with `/telegram stop`. `setup` and `start` cannot run simultaneously — they race on the Telegram `.offset` file during PIN pairing."
   Stop here.

2. Run:
   ```
   Bash: bash ${CLAUDE_PLUGIN_ROOT}/scripts/setup.sh
   ```

3. After it exits, read `~/.claude/channels/telegram/.env` and print a masked summary (token prefix + chat_id prefix + voice enabled/disabled).

## `status`

Read `~/.claude/channels/telegram/.env`, call `TaskList()`, and run `bash scripts/mode.sh get`. Print a compact block:

```
🤖 forge-telegram status
  Token:    <masked or NOT SET>
  Chat ID:  <masked or NOT SET>
  Voice:    enabled | disabled (no OPENAI_API_KEY)
  Listener: RUNNING 📡 | STOPPED ⏸
  Mode:     strict | conversational | trust
```

Listener is RUNNING if `TaskList()` returns a task whose description contains `"Telegram inbound messages"`; otherwise STOPPED.

Masking: first 4 chars + `…` + last 4 chars.

## `send <sender> <message>`

Send a message from the main session to Telegram.

1. Parse `$ARGUMENTS` — the first word is the sender (quoted if it contains spaces), the rest is the message body. If the user omitted the sender, default to the current session's role — typically `"Main session"`, or if the skill is being invoked from inside a recognizable orchestration context, use that role (e.g. `"Orchestrator"`, `"Plan Executor"`).

2. Run:
   ```
   Bash: bash ${CLAUDE_PLUGIN_ROOT}/scripts/send.sh "<sender>" "<message>"
   ```

3. Report: `"✓ Sent from <sender>"` on success, or the script's stderr on failure.

**The sender is always present.** Never call `send.sh` without it. The user needs to know which session/role is speaking in the Telegram chat when multiple Claude sessions may be writing.

## `mode [show|strict|conversational|trust]`

Get or set the assistant's **response mode** for Telegram events. The current
mode is persisted in `~/.claude/channels/telegram/mode` so it survives compact
/ clear / session restart.

### `mode` or `mode show`

Print the current mode by running `bash scripts/mode.sh get`. Example output:

```
🎚️ Current Telegram mode: strict
     (display + 👀 ack only — I will not reply or execute anything
      from Telegram text until you tell me to in this terminal)
```

Adapt the description line to match the active mode — see the full descriptions in SKILL.md → "Response modes".

### `mode strict`

Set the mode to **strict** (the safe default):

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/mode.sh set strict
```

Confirm: `"🎚️ Telegram mode → strict. I will ack with 👀 and display, but not act on Telegram content."`

### `mode conversational`

Set to **conversational**:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/mode.sh set conversational
```

Confirm: `"🎚️ Telegram mode → conversational. I will reply to greetings and non-imperative messages, but still defer commands to this terminal."`

### `mode trust`

Set to **trust** (remote control — the terminal user should confirm they
understand the risk before switching to this mode):

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/mode.sh set trust
```

Confirm: `"🎚️ Telegram mode → trust. ⚠ I will now execute Telegram messages as if you typed them in this terminal. Use /telegram mode strict to revoke."`

### Anything else

If the argument isn't one of the five recognized values, print the usage:

```
/telegram mode — get or set the response mode

  mode                 Show current mode
  mode show            Show current mode (same as above)
  mode strict          Display + 👀 ack only (default, safe)
  mode conversational  Also reply conversationally to non-imperative messages
  mode trust           Also execute Telegram messages as if typed in terminal
```

## Anything else (usage)

Print:

```
/telegram — Telegram bridge control

Subcommands:
  start                         Start the inbound listener (default)
  stop                          Shut down the listener
  setup                         One-time config: bot token, PIN pair, optional Whisper
  status                        Show configuration + listener state + current mode
  send <sender> <msg>           Send a message to the Telegram chat
  mode [strict|conversational|trust]
                                Get or set the response mode (persists to disk)
```
