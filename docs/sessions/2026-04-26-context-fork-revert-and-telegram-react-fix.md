## Session: 2026-04-26 — context-fork experiment reverted, forge-telegram closing reaction fix shipped

### Changes made

- forge-keeper: added `context: fork` to `skills/forge-keeper/SKILL.md`, released as v1.17.0 (commit 85a2742). **Reverted** later the same session (commit 3a0a261, tag deleted local + remote) once the assumption underlying the change turned out to be wrong.
- forge-telegram 1.1.0 → 1.2.0:
  - `scripts/react.sh` — classifies Telegram API rejections (`REACTION_INVALID`, `MESSAGE_NOT_MODIFIED`, `MESSAGE_NOT_FOUND`, `Too Many Requests`/`FLOOD_WAIT`, `chat not found`) and appends timestamped `ok`/`FAIL` lines to `listen.log` for every call.
  - `skills/telegram/SKILL.md` step 3.5 — added "Closing reaction — mandatory checklist" block making 👍/👎/🤔 obligatory at the end of every built-in.
  - `skills/telegram/references/subcommands.md` — per-built-in cierres marked `**Closing reaction (mandatory)**`; removed the duplicated 👀 ack (already handled by the inbound flow's step 2.5).
  - `skills/telegram/references/operational.md` — listen.log writer table updated to include react.sh.
- Released as v1.17.0 (commit 6277ff3, tag v1.17.0).

### Decisions taken

- **Reverted the context:fork experiment via revert+tag-delete (option A from rollback prompt)** rather than hard reset + force push. Histórico shows release → revert → re-release; honest about what happened, no rewriting of pushed history.
- **Telegram fix scope: instructions + diagnostics, not a wrapper script.** Wrapper would have been more robust (closing reaction by construction) but required refactoring all built-ins. Instead: prominent SKILL.md checklist + classified errors in react.sh + audit log to enable post-mortem when reactions still go missing. If the bug persists the audit log will tell us whether it's the model forgetting (rerun with wrapper) or the API rejecting (different fix).

### Context for next session

- **`context: fork` works since Claude Code v2.1.101 BUT does not inherit conversational history.** The fork starts blank with system prompt + skill body + args. Documented in `memory/project_context_fork.md` and CLAUDE.md gotcha. Do not re-attempt the forge-keeper:fork wiring on the assumption that the subagent will "know what we did".
- **Plugin cache does not auto-update on marketplace bump.** `/reload-plugins` reloads the existing cache version; it does not pull a newer one. For in-place iteration: copy the modified files into `~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/` directly and reload. Documented in CLAUDE.md gotcha.
- **Pending bug — `transcribe.sh` voice transcription is silently broken under the Bash sandbox on macOS.** It calls `mktemp` without an explicit template, which resolves to `/var/folders/.../T/` — sandbox-blocked, same root cause as the `.offset` runaway. Visible in `listen.log` as `mktemp: mkstemp failed ... Operation not permitted` + `[transcribe] mktemp failed`. Voice messages fall through to "OPENAI_API_KEY not set" even with the key set. Fix: route temp into `${TELEGRAM_STATE_DIR:-~/.claude/channels/telegram}/inbox/.tmp/` and add to allowlist. Captured in `memory/project_forgetelegram.md`.
