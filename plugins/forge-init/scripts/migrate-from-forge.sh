#!/usr/bin/env bash
#
# Migrate from the forge-* plugin naming (pre-v3.0.0) to df-* (v3.0.0+).
#
# What this script does:
#   1. Reads ~/.claude/settings.json and detects which forge-* plugins are
#      enabled.
#   2. Rewrites enabledPlugins keys: `forge-X@dev-forge` → `df-X@dev-forge`
#      for currently-active plugins. Drops keys for plugins that no longer
#      exist (forge-executor / forge-ui-expert / forge-ralph / forge-extended-dev).
#   3. Updates .claude/settings.local.json if it has forge-* allowlist
#      patterns (`bash **/forge-X/scripts/*.sh` etc.).
#   4. Backs up both files before modifying.
#   5. Prints the next-step slash commands the user must run to actually
#      uninstall the old cached plugins and install the new ones.
#
# Why both file rewrite AND slash commands? The settings rewrite swaps the
# enabled flag — but Claude Code's plugin cache still holds the old forge-*
# directories. The slash commands clean the cache and pull df-* into it.
# Without the file rewrite, /plugin install df-X would land but the
# enabledPlugins map would still reference the dead forge-X entries.
#
# Usage (from any directory; modifies user-level settings.json):
#   bash "${CLAUDE_PLUGIN_ROOT}/scripts/migrate-from-forge.sh"
#   bash "${CLAUDE_PLUGIN_ROOT}/scripts/migrate-from-forge.sh" --dry-run

set -uo pipefail
trap 'exit 0' ERR

DRY_RUN=0
if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN=1
fi

USER_SETTINGS="${HOME}/.claude/settings.json"
PROJECT_SETTINGS="${PWD}/.claude/settings.local.json"
TS=$(date -u +%Y%m%dT%H%M%SZ)

echo "[migrate] === forge-* → df-* migration ==="
echo

# ---------------------------------------------------------------------------
# 1. Map of forge-X → df-X (16 plugins) + the 4 removed-pre-v3 plugins
# ---------------------------------------------------------------------------
RENAMES="forge-init=df-init
forge-keeper=df-keeper
forge-superpowers=df-superpowers
forge-plugin-dev=df-plugin-dev
forge-deep-review=df-deep-review
forge-hookify=df-hookify
forge-security=df-security
forge-commit=df-commit
forge-frontend-design=df-frontend-design
forge-telegram=df-telegram
forge-proactive-qa=df-proactive-qa
forge-context-mcp=df-context-mcp
forge-export=df-export
forge-brainstorming=df-brainstorming
forge-profiles=df-profiles
forge-ui-forge=df-ui-forge"

# Plugins removed in earlier releases — drop their entries entirely.
# (forge-extended-dev was renamed to forge-deep-review in v2.0.0; we'd keep
# the data only if the user already migrated then. Otherwise it's stale.)
REMOVED="forge-executor
forge-ui-expert
forge-ralph
forge-extended-dev"

# ---------------------------------------------------------------------------
# 2. Inspect ~/.claude/settings.json — which forge-* are enabled?
# ---------------------------------------------------------------------------
if [ ! -f "$USER_SETTINGS" ]; then
  echo "[migrate] no ~/.claude/settings.json — nothing to migrate."
  exit 0
fi

ENABLED=$(python3 -c "
import json
try:
    d = json.load(open('$USER_SETTINGS'))
    plugins = d.get('enabledPlugins', {})
    for k, v in plugins.items():
        if v and k.startswith('forge-') and k.endswith('@dev-forge'):
            print(k.split('@')[0])
except Exception as e:
    print(f'ERROR:{e}', file=__import__('sys').stderr)
" 2>&1)

if [ -z "$ENABLED" ]; then
  echo "[migrate] no forge-* plugins enabled in $USER_SETTINGS"
  exit 0
fi

echo "[migrate] currently enabled forge-* plugins:"
echo "$ENABLED" | sed 's/^/  /'
echo

# ---------------------------------------------------------------------------
# 3. Plan: which to rename, which to drop
# ---------------------------------------------------------------------------
TO_RENAME=""
TO_DROP=""
TO_INSTALL=""

while IFS= read -r plugin; do
  [ -z "$plugin" ] && continue
  if echo "$REMOVED" | grep -q "^$plugin$"; then
    TO_DROP="${TO_DROP}${plugin}\n"
  else
    new=$(echo "$RENAMES" | grep "^$plugin=" | cut -d= -f2)
    if [ -n "$new" ]; then
      TO_RENAME="${TO_RENAME}${plugin} -> ${new}\n"
      TO_INSTALL="${TO_INSTALL}${new}\n"
    fi
  fi
done <<< "$ENABLED"

if [ -n "$TO_RENAME" ]; then
  echo "[migrate] renaming:"
  printf "$TO_RENAME" | sed 's/^/  /'
  echo
fi

if [ -n "$TO_DROP" ]; then
  echo "[migrate] dropping (no longer in marketplace):"
  printf "$TO_DROP" | sed 's/^/  /'
  echo
fi

if [ "$DRY_RUN" = "1" ]; then
  echo "[migrate] --dry-run: no files modified"
  exit 0
fi

# ---------------------------------------------------------------------------
# 4. Rewrite ~/.claude/settings.json
# ---------------------------------------------------------------------------
BACKUP="${USER_SETTINGS}.bak.${TS}"
cp "$USER_SETTINGS" "$BACKUP"
echo "[migrate] backed up $USER_SETTINGS → $BACKUP"

python3 - "$USER_SETTINGS" "$RENAMES" "$REMOVED" <<'PYEOF'
import json
import sys

settings_path, renames_text, removed_text = sys.argv[1], sys.argv[2], sys.argv[3]

renames = {}
for line in renames_text.strip().splitlines():
    if "=" in line:
        old, new = line.split("=", 1)
        renames[old.strip()] = new.strip()

removed = {p.strip() for p in removed_text.strip().splitlines() if p.strip()}

with open(settings_path) as f:
    data = json.load(f)

plugins = data.get("enabledPlugins", {})
new_plugins = {}
n_renamed = n_dropped = n_kept = 0

for key, value in plugins.items():
    if "@" in key:
        name, host = key.split("@", 1)
    else:
        name, host = key, ""
    full_host = f"@{host}" if host else ""

    if name in removed:
        n_dropped += 1
        continue
    if name in renames:
        new_key = f"{renames[name]}{full_host}"
        new_plugins[new_key] = value
        n_renamed += 1
    else:
        new_plugins[key] = value
        n_kept += 1

data["enabledPlugins"] = new_plugins

with open(settings_path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")

print(f"[migrate] settings.json updated: {n_renamed} renamed, {n_dropped} dropped, {n_kept} unchanged")
PYEOF

# ---------------------------------------------------------------------------
# 5. Update project-level .claude/settings.local.json if present
# ---------------------------------------------------------------------------
if [ -f "$PROJECT_SETTINGS" ]; then
  if grep -q "forge-" "$PROJECT_SETTINGS"; then
    PROJECT_BACKUP="${PROJECT_SETTINGS}.bak.${TS}"
    cp "$PROJECT_SETTINGS" "$PROJECT_BACKUP"
    echo "[migrate] backed up $PROJECT_SETTINGS → $PROJECT_BACKUP"

    python3 - "$PROJECT_SETTINGS" "$RENAMES" <<'PYEOF'
import json, sys, re

settings_path, renames_text = sys.argv[1], sys.argv[2]
renames = {}
for line in renames_text.strip().splitlines():
    if "=" in line:
        old, new = line.split("=", 1)
        renames[old.strip()] = new.strip()

with open(settings_path) as f:
    data = json.load(f)

# Recursively walk and rewrite string values containing forge-X tokens.
def rewrite(obj):
    if isinstance(obj, str):
        new = obj
        for old, new_name in renames.items():
            new = new.replace(old, new_name)
        return new
    if isinstance(obj, list):
        return [rewrite(x) for x in obj]
    if isinstance(obj, dict):
        return {rewrite(k) if isinstance(k, str) else k: rewrite(v) for k, v in obj.items()}
    return obj

new_data = rewrite(data)
with open(settings_path, "w") as f:
    json.dump(new_data, f, indent=2)
    f.write("\n")
print("[migrate] project settings.local.json updated")
PYEOF
  else
    echo "[migrate] $PROJECT_SETTINGS has no forge-* references — skipping"
  fi
fi

# ---------------------------------------------------------------------------
# 6. Print the slash-command sequence the user must run
# ---------------------------------------------------------------------------
echo
echo "[migrate] === MANUAL STEP ==="
echo
echo "settings.json updated. The plugin cache still holds the old forge-* directories."
echo "To clean the cache and pull df-* in, paste this block into Claude Code:"
echo
echo "---8<--- copy below ---"
while IFS= read -r line; do
  [ -z "$line" ] && continue
  old=$(echo "$line" | sed 's/ -> .*//')
  echo "/plugin uninstall $old"
done <<< "$(printf "$TO_RENAME")"
while IFS= read -r line; do
  [ -z "$line" ] && continue
  echo "/plugin uninstall $line"
done <<< "$(printf "$TO_DROP")"
echo
while IFS= read -r line; do
  [ -z "$line" ] && continue
  echo "/plugin install $line"
done <<< "$(printf "$TO_INSTALL")"
echo "---8<--- copy above ---"
echo
echo "Then run /reload-plugins (or start a fresh session)."
echo "[migrate] done."
exit 0
