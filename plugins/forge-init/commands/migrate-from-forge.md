---
description: Reusable migration helper for plugin renames in the dev-forge marketplace. Detects which plugins are enabled in ~/.claude/settings.json, rewrites the keys to a target naming, updates project-level allowlist patterns, and prints the slash-command block the user pastes to refresh the cache. Currently scaffolded for a hypothetical forge-* → df-* rename — edit the RENAMES map in scripts/migrate-from-forge.sh before running.
---

> **Status (2026-04-27):** This helper exists as a template. The forge-* → df-* rename was prepared in v3.0.0/v3.1.0 and reverted before any consumer adopted it. The script's hardcoded `RENAMES` map still encodes that rename — edit it (and `REMOVED`) before running if you ever do a real rename in this marketplace.

Run the migration helper from `forge-init`. This command does the file edits automatically and gives the user the slash-command block to paste back.

## What the script does

1. Reads `~/.claude/settings.json` and finds enabled plugins matching `forge-*@dev-forge`.
2. Backs up `settings.json` (timestamped `.bak.YYYYMMDDTHHMMSSZ` next to it).
3. Rewrites `enabledPlugins` keys: `forge-X@dev-forge` → `df-X@dev-forge` for the 16 renamed plugins. Drops keys for plugins that were removed in earlier releases (`forge-executor`, `forge-ui-expert`, `forge-ralph`, `forge-extended-dev`).
4. If `.claude/settings.local.json` exists in the current project AND contains `forge-*` allowlist patterns (e.g., `bash **/forge-keeper/scripts/*.sh`), backs it up and rewrites those tokens as well.
5. Prints the slash-command sequence (uninstall old + install new) for the user to paste into Claude Code.

## Process

### Step 1 — Dry-run

Show the user what would happen without modifying anything:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/migrate-from-forge.sh" --dry-run
```

The dry-run prints:
- The list of `forge-*` plugins currently enabled.
- The rename map (`forge-X → df-X`) for each.
- Any plugins that will be dropped because they no longer exist in the marketplace.

### Step 2 — Confirm with the user

Show the dry-run output and ask: **"Apply this migration?"** Wait for explicit confirmation before continuing.

### Step 3 — Apply

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/migrate-from-forge.sh"
```

This rewrites the settings files (with backups) and prints the slash-command block.

### Step 4 — Tell the user to paste

The script's last lines are a `---8<---` delimited block of `/plugin uninstall` + `/plugin install` commands. Copy that block into Claude Code's input. The `/plugin` command is interactive (per Claude Code), so the user pastes them.

After all installs finish:

```
/reload-plugins
```

Or close and reopen the session — both pick up the new cache entries.

### Step 5 — Verify

Inspect the result:

```bash
python3 -c "import json; d=json.load(open('$HOME/.claude/settings.json')); [print(k) for k,v in d.get('enabledPlugins',{}).items() if v]"
```

All entries should start with `df-`. None should start with `forge-`.

## Rollback

If anything goes wrong, the script left timestamped backups:

```bash
ls -la ~/.claude/settings.json.bak.*
ls -la .claude/settings.local.json.bak.* 2>/dev/null
```

Restore by `cp <backup> <original>`.

## Notes

- **State is preserved across the rename.** `~/.claude/channels/telegram/`, `.ui-forge/` directories, sandbox allowlists for paths the plugins write — all unchanged. No need to re-run `/df-telegram:telegram setup` if you had `forge-telegram` paired.
- **Hooks installed by old plugins** (forge-keeper context-watch, forge-security reminder) live inside the cache directories pointed at via `${CLAUDE_PLUGIN_ROOT}` — when the new df-X plugins are installed, hooks resolve correctly via the new cache paths.
- **The script is idempotent** — running it twice on an already-migrated `settings.json` is a no-op (it finds no `forge-*` entries to rewrite).
- **This command lives in the disposable plugin `df-init`** — install it, run the migration once, then uninstall.
