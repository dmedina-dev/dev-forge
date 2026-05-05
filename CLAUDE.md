# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Dev Forge

Personal plugin marketplace for Claude Code. Curated collection of independent plugins that can be installed individually or all at once.

## Architecture

Each plugin is **independent** — install, test, remove any plugin without affecting others. The marketplace is the catalog, not a bundle.

```
dev-forge/
├── .claude-plugin/marketplace.json    ← catalog of all available plugins
├── .upstream/                         ← persistent upstream clones (gitignored)
├── plugins/
│   ├── forge-init/                    ← bootstrapper (disposable)
│   ├── forge-keeper/                  ← context maintenance
│   ├── forge-superpowers/             ← core skills (curated from obra/superpowers)
│   ├── forge-plugin-dev/              ← plugin development toolkit
│   ├── forge-deep-review/             ← specialized review agents + automated PR review
│   ├── forge-hookify/                 ← custom hook rules engine
│   ├── forge-security/                ← security reminder hooks
│   ├── forge-commit/                  ← commit/PR commands + marketplace release
│   ├── forge-frontend-design/         ← frontend UI/UX design
│   ├── forge-telegram/                ← Telegram listener + sender (bash + Monitor, event-driven)
│   ├── forge-proactive-qa/            ← autonomous QA agent (requires Playwright)
│   ├── forge-context-mcp/             ← MCP server setup guide (disposable)
│   ├── forge-export/                  ← marketplace export wizard (disposable)
│   ├── forge-brainstorming/           ← teammate-driven lifecycle (requires forge-superpowers)
│   ├── forge-profiles/                ← plugin profile manager (independent)
│   ├── forge-ui-forge/                ← UI prototyping with per-project registry + overlay annotation
│   ├── forge-mattpocock/              ← alternative skills framework (curated from mattpocock/skills)
│   └── forge-deepthink/               ← structured /deepthink protocol (independent)
└── docs/
    ├── dependencies.md                ← dependency map between plugins
    └── customizations-pattern.md      ← vendor + customizations pattern
```

## Plugin independence

- Every plugin works standalone — no implicit dependencies
- If a plugin REQUIRES another, document it in `dependencies.md`
- Testing with/without a plugin: `claude --plugin-dir plugins/<name>`
- Install all: install every plugin from the marketplace
- Install subset: pick only what you need

## When to unify vs separate

**Separate** (default): skills, agents, commands that make sense alone
**Unified** (exception): when a hook + skill + agent form a cohesive unit that breaks without each other (e.g., forge-keeper's context-watch hook + sync skill)

## Curation workflow

1. Find useful skill/agent/hook (superpowers, anthropic, custom)
2. Create independent plugin in `plugins/<name>/`
3. Note origin in SKILL.md if curated from external source
4. For external plugins: create `customizations.json` (see `docs/customizations-pattern.md`)
5. Add to marketplace.json
6. Test independently: `claude --plugin-dir plugins/<name>`
7. Push — available for installation

## External plugin customizations

External plugins follow a **vendor + customizations** pattern — see @docs/customizations-pattern.md for the full schema and update workflow. Native plugins (forge-init, forge-keeper, forge-proactive-qa, forge-brainstorming, forge-profiles, forge-ui-forge) don't need customizations.json. External plugins currently in the marketplace: forge-superpowers (obra/superpowers), forge-plugin-dev / forge-deep-review / forge-hookify / forge-security / forge-commit (anthropics/claude-code), forge-frontend-design (anthropics/claude-plugins-official), and forge-mattpocock (mattpocock/skills).

## Conventions

- SKILL.md frontmatter: `name` and `description` required
- Command .md frontmatter: `description` required
- Reference files: plain markdown, no frontmatter
- Hook scripts: `${CLAUDE_PLUGIN_ROOT}` for paths, always exit 0
- JSON: validate with `python3 -m json.tool`
- Skills from external sources: note origin in a comment at top of SKILL.md

## Commands

```bash
# Test any plugin independently
claude --plugin-dir plugins/<name>

# Test multiple together
claude --plugin-dir plugins/forge-init --plugin-dir plugins/forge-keeper
```

## Dependencies

Hard dependency: **forge-brainstorming** requires **forge-superpowers**. Full matrix in @docs/dependencies.md.

## Exemplars

Reference plugins for how things should be done — see @docs/exemplars.md.

## Gotchas

- marketplace.json `source.url` must use https (not git@) for public access
- Plugin directories need `.claude-plugin/plugin.json` to be recognized
- Skills trigger based on description text — vague descriptions = unreliable triggers
- When updating from upstream, use `/update-check` which syncs via `.upstream/` persistent clones (top-down: copy upstream → apply customizations)
- Custom `added` files in customizations.json MUST be documented or rsync `--delete` will remove them during sync
- `/release` command only works in marketplace repos (requires `.claude-plugin/marketplace.json`)
- context-watch.sh uses `trap 'exit 0' ERR` instead of `set -e` for safety
- forge-telegram requires the `Monitor` tool (Claude Code Apr 2026+), plus `curl`, `jq`, `openssl`. Listener writes state to `~/.claude/channels/telegram/` — if the Bash sandbox is enabled, add the paths from `plugins/forge-telegram/skills/telegram/references/operational.md` § Sandbox gotcha to `sandbox.filesystem.allowWrite` in `.claude/settings.local.json`, or the listener runs into a silent stuck-state loop.
- forge-proactive-qa requires Playwright installed in the target project
- **Bash sandbox blocks writes outside project root.** Plugins that store state in `~/.claude/channels/<plugin>/` (or anywhere outside the project workspace) must list every writable file in `sandbox.filesystem.allowWrite`, or `echo > file` silently returns `rc=1` under `set -uo pipefail`. Avoid `mktemp -t` / `$TMPDIR` — on macOS this resolves to `/var/folders/…/T/` which is also blocked.
- `/forge-keeper:heal-plugin-cache` recovers orphaned sessions after a plugin version bump — it symlinks stale `cache/<marketplace>/<plugin>/<old-version>/` entries to the current installed version so sessions pinned to the old path keep working.
- `context: fork` in a plugin SKILL.md frontmatter works since Claude Code v2.1.101 — runs the skill in an isolated subagent (its tool calls do not appear in the main transcript). But it does **NOT** inherit the parent's conversation history: the fork starts blank with system prompt + skill body + invocation args. Useful for keeping heavy analysis out of the main context; useless for "let the subagent reuse what we just discussed" — pass relevant facts as args or run inline instead.
- Plugin cache does **not** auto-update after a marketplace version bump. `/reload-plugins` only reloads what's already in `~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/`; it does not pull a newer version published to `marketplace.json`. Update via the `/plugin` UI flow. For in-place iteration with a live user (no full update cycle), copy the modified files from the working `plugins/<name>/` tree directly into the existing cache directory and `/reload-plugins` — same effect, contained to that session.
- Sub-agent dispatching: `Agent({subagent_type: "X"})` errors hard if "X" is not in the registry — there is **no fallback** to `general-purpose`. Smoke-test orchestrators by dispatching one of their target `subagent_type` strings directly via Agent; if it errors with `Agent type 'X' not found. Available agents: ...`, the orchestrator's first dispatch will halt the flow. This is how forge-executor's broken state was diagnosed in the v2.0.0 prune (BackendImplementer/FrontendImplementer/Configurator/InfraArchitect/Reviewer/Analyst all referenced but never registered).
- Marketplace version semantics: bump `marketplace.json metadata.version` to the next major (e.g., 1.x → 2.0) when removing or renaming plugins. These are breaking changes for users with the plugins installed — their cache will go stale and `/reload-plugins` cannot recover the old plugin name. Document the breaking change in commit messages.
- `dependencies` is a **reserved field** in Claude Code's marketplace schema and **must be a flat array of plugin name strings** (`["other-plugin"]`). The validator rejects anything else (object, nested) with `Invalid input: expected array, received object` and refuses to load the entire marketplace — so `/plugin marketplace add` fails for every consumer. Do NOT redefine the shape (e.g. `{"required": [...]}` or `{"required": [...], "recommended": [...]}`) treating it as a custom extension. If you need richer dependency metadata, store it under a different key (`writes_outside_project_root` is an example of a dev-forge-specific extension that is safe because the name isn't reserved). The bug landed in v2.1.1 and was fixed in v2.2.1; `python3 -m json.tool` only validates JSON syntax, not Claude Code schema — run `bash scripts/marketplace-health.sh` before pushing any change to `marketplace.json` or `plugin.json` (it explicitly tests for this regression and several other modes).
- **Schema-shape changes require auditing every script that reads the affected field.** When a `marketplace.json` field's shape changes (like `dependencies` flipping from `{"required":[]}` to flat `[]` in v2.2.1), every consumer in `scripts/` that parses it must be updated in the same change. The `generate-install-all.sh` bug stayed latent through v2.2.1 → v2.3.0 because `forge-brainstorming` is the only non-empty consumer and the script wasn't run on a marketplace including it; it would have crashed with `AttributeError: 'list' object has no attribute 'get'` the moment it was. When you change a reserved-field shape, `grep -r '<field-name>' scripts/` and update every reader before pushing.
