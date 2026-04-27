#!/usr/bin/env bash
#
# Regenerate plugins/forge-init/commands/install-all.md from marketplace.json.
#
# This is the source of truth for which plugins exist, their descriptions, and
# their hard dependencies. Without this script, install-all.md drifts from the
# catalog every time a plugin is added/removed/renamed and consumers see stale
# or broken install plans.
#
# Run from the repo root:
#   bash scripts/generate-install-all.sh
#
# The script reads marketplace.json, classifies each plugin as "working" or
# "configuration" (disposable) using a hardcoded list, and writes the markdown.
# It emits to stdout AND writes the file in place. Diff after running.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MARKETPLACE="$REPO_ROOT/.claude-plugin/marketplace.json"
OUTPUT="$REPO_ROOT/plugins/forge-init/commands/install-all.md"

if [ ! -f "$MARKETPLACE" ]; then
  echo "[generate-install-all] marketplace.json not found at $MARKETPLACE" >&2
  exit 1
fi

python3 - "$MARKETPLACE" "$OUTPUT" <<'PYEOF'
import json
import sys
from pathlib import Path

marketplace_path, output_path = Path(sys.argv[1]), Path(sys.argv[2])

# Plugins that are disposable / configuration-only — install for a one-shot
# task, then uninstall. Keep this list in sync with the descriptions in the
# plugins themselves (each notes "disposable" or "uninstall after use").
DISPOSABLE = {
    "forge-init",
    "forge-plugin-dev",
    "forge-context-mcp",
    "forge-export",
}

# Friendly one-liners overlay. marketplace.json descriptions are usually too
# verbose for the install-all table; use a short label here. Keys must exist
# in marketplace.json or we error out (so renames are caught).
SHORT_LABELS = {
    "forge-keeper":          "Context maintenance: sync, status, recall, segment-doc + hooks",
    "forge-superpowers":     "TDD, debugging, parallel agents, code review, worktrees, plans",
    "forge-deep-review":     "Specialized review agents + automated PR review",
    "forge-brainstorming":   "Teammate-driven full lifecycle with 5 persistent agents",
    "forge-commit":          "Git commit and PR commands",
    "forge-security":        "Security reminder hooks (9 vulnerability patterns)",
    "forge-hookify":         "Custom hook rules engine with .local.md rules",
    "forge-profiles":        "Plugin profile manager — switch plugin sets per work mode",
    "forge-frontend-design": "Distinctive, production-grade UI/UX design",
    "forge-ui-forge":        "Iterative UI prototyping + live overlay over an existing dev server",
    "forge-telegram":        "Telegram bridge — listener + sender (bash + Monitor)",
    "forge-proactive-qa":    "Autonomous Playwright QA agent (Telegram-notified)",
    "forge-init":            "Project bootstrapper + migrate-from-forge helper",
    "forge-plugin-dev":      "Plugin development toolkit",
    "forge-context-mcp":     "MCP server setup guide (Context7, Serena, XRAY)",
    "forge-export":          "Marketplace export wizard",
}

DISPOSABLE_WHEN = {
    "forge-init":         "New project → `/plugin install forge-init` → `/forge-init:init` → uninstall",
    "forge-plugin-dev":   "Developing plugins → `/plugin install forge-plugin-dev` → build → uninstall",
    "forge-context-mcp":  "Setting up codebase intelligence → configure → uninstall",
    "forge-export":       "Forking dev-forge for another org → export → uninstall",
}

with open(marketplace_path) as f:
    catalog = json.load(f)

plugins = {p["name"]: p for p in catalog["plugins"]}
missing_labels = sorted(set(plugins) - set(SHORT_LABELS))
if missing_labels:
    sys.exit(
        f"[generate-install-all] no SHORT_LABELS entry for: {missing_labels}.\n"
        "Edit scripts/generate-install-all.sh and add a one-liner for each."
    )

working_names = [n for n in plugins if n not in DISPOSABLE]
disposable_names = [n for n in plugins if n in DISPOSABLE]

# Sort working in install order: dependencies first, then independent.
def sort_working(names):
    by_name = {n: plugins[n] for n in names}
    deps = {n: set((by_name[n].get("dependencies") or {}).get("required", [])) for n in names}
    ordered, seen = [], set()
    def visit(n):
        if n in seen: return
        for d in deps.get(n, ()):
            if d in by_name:
                visit(d)
        seen.add(n); ordered.append(n)
    for n in names:
        visit(n)
    return ordered

working_ordered = sort_working(working_names)


def describe(name):
    return SHORT_LABELS[name]


def requires(name):
    return ", ".join((plugins[name].get("dependencies") or {}).get("required", [])) or "-"


lines = []
lines.append("---")
disposable_csv = ", ".join(sorted(DISPOSABLE & set(plugins)))
lines.append(
    "description: Install all dev-forge working plugins. Configuration plugins "
    f"({disposable_csv}) are shown separately — install them on demand. Resolves dependencies and lets user exclude plugins."
)
lines.append("---")
lines.append("")
lines.append("Install all dev-forge **working** plugins — the daily driver set.")
lines.append("")
lines.append("> Generated from `.claude-plugin/marketplace.json` by `scripts/generate-install-all.sh`. Do not hand-edit; run the script and commit the diff.")
lines.append("")
lines.append("## Plugin catalog")
lines.append("")
lines.append("### Working plugins (installed by this command)")
lines.append("")
lines.append("Always-on plugins for daily development work.")
lines.append("")
lines.append("| Plugin | Description | Requires |")
lines.append("|--------|-------------|----------|")
for n in working_ordered:
    lines.append(f"| {n} | {describe(n)} | {requires(n)} |")
lines.append("")
lines.append("### Configuration plugins (NOT installed by this command)")
lines.append("")
lines.append("Install when needed, uninstall after — they consume context without adding")
lines.append("value when not actively being used.")
lines.append("")
lines.append("| Plugin | Purpose | When to install |")
lines.append("|--------|---------|-----------------|")
for n in disposable_names:
    lines.append(f"| {n} | {describe(n)} | {DISPOSABLE_WHEN.get(n, '-')} |")
lines.append("")
lines.append("## Process")
lines.append("")
lines.append("### Step 1: Check what's already installed")
lines.append("")
lines.append("List plugins already installed in this project to avoid reinstalling.")
lines.append("")
lines.append("### Step 2: Resolve dependencies")
lines.append("")
hard_deps = {n: requires(n) for n in working_ordered if requires(n) != "-"}
if hard_deps:
    for child, dep in hard_deps.items():
        lines.append(f"- **{child} requires {dep}** — install {dep} first")
    lines.append("- All other working plugins are independent")
else:
    lines.append("- All working plugins are independent")
lines.append("")
lines.append("### Step 3: Present install plan")
lines.append("")
lines.append("```")
lines.append("## Dev Forge — Working Plugins Install Plan")
lines.append("")
lines.append("Already installed: [list or \"none\"]")
lines.append("")
lines.append("### Will install (in order):")
for i, n in enumerate(working_ordered, start=1):
    note = ""
    req = requires(n)
    if req != "-":
        note = f" (requires {req} ✓)"
    lines.append(f"{i}. {n} — {describe(n)}{note}")
lines.append("")
lines.append("### Not included (configuration plugins — install on demand):")
for n in disposable_names:
    when = DISPOSABLE_WHEN.get(n, "")
    short = when.split('→')[0].strip() if '→' in when else f"on demand"
    lines.append(f"- {n} → /plugin install {n} ({short})")
lines.append("")
lines.append("Want to exclude any working plugins? Otherwise proceed.")
lines.append("```")
lines.append("")
lines.append("The user may exclude plugins from the working set. Adjust the plan.")
lines.append("")
lines.append("### Step 4: Install in order")
lines.append("")
for i, n in enumerate(working_ordered, start=1):
    note = " (dependency first)" if any(n in (plugins[m].get("dependencies") or {}).get("required", []) for m in working_ordered) else ""
    lines.append(f"{i}. {n}{note}")
lines.append("")
lines.append("For each:")
lines.append("```")
lines.append("/plugin install <name>")
lines.append("```")
lines.append("")
lines.append("### Step 5: Post-install summary")
lines.append("")
lines.append("```")
lines.append(f"Dev Forge — {len(working_ordered)} working plugins installed")
lines.append("")
lines.append("Working:")
for n in working_ordered:
    lines.append(f"  {n} ✓")
lines.append("")
lines.append("Configuration (install when needed):")
for n in disposable_names:
    lines.append(f"  {n} → /plugin install {n}")
lines.append("")
lines.append("Next: /forge-keeper:status")
lines.append("```")

text = "\n".join(lines) + "\n"
output_path.write_text(text)
print(f"[generate-install-all] wrote {output_path} ({len(working_ordered)} working, {len(disposable_names)} configuration)")
PYEOF
