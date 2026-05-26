# Code Exemplars

Reference plugins that demonstrate the target patterns for dev-forge.
When creating new plugins, use these as your model — read the actual files.

## Native plugin
- **Plugin:** `plugins/forge-keeper/`
- **Pattern:** Cohesive plugin with hooks + skill + commands + references
- **Lesson:** Shows when unification is justified — the PreCompact hook, SessionStart(clear) rescue, /sync command, and SKILL.md form a unit that breaks if split apart. Also demonstrates proper reference file organization (4 reference docs for progressive disclosure) and descriptive plugin.json with meaningful keywords.

Key files to study:
- `.claude-plugin/plugin.json` — complete metadata with keywords
- `hooks/hooks.json` — prompt-based hooks for PreCompact and SessionStart(clear)
- `skills/forge-keeper/SKILL.md` — skill with trigger phrases in description
- `commands/sync.md` — command with description frontmatter
- `skills/forge-keeper/references/` — plain markdown references (no frontmatter)

## Curated plugin (vendor + customizations)
- **Plugin:** `plugins/forge-superpowers/`
- **Pattern:** External plugin with selective curation via customizations.json
- **Lesson:** Shows the vendor + customizations pattern at scale — 19 documented customizations covering exclusions (CI, other platforms, docs), removals (replaced skills), and modifications (trigger sensitivity, platform detection). Each customization has a clear reason explaining the WHY. The upstream_status block enables future update checks without losing local changes.

Key files to study:
- `.claude-plugin/customizations.json` — full customization manifest with origin tracking
- `.claude-plugin/plugin.json` — re-authored metadata noting curation source
- `hooks/hooks.json` — command hook using `${CLAUDE_PLUGIN_ROOT}` for paths
- `skills/brainstorming/SKILL.md` — example of modified trigger (custom-12)

## Native plugin with context-offloading subagents
- **Plugin:** `plugins/forge-ui-forge/` (since v0.7.0)
- **Pattern:** Main session orchestrates; specialized subagents do the heavy file work, receiving paths + small parameter payloads — never inline content.
- **Lesson:** When a workflow produces large artefacts (HTML files, generated specs, sizeable JSON) across multiple iterations, the main session shouldn't hold those artefacts in its own context. Three subagents (`ui-forge-variator` for Phase 2 variation HTML, `ui-forge-iterator` for Phase 3 pin rounds, `ui-forge-distiller` for Phase 4 bundle + validator) read/write the files directly and return ≤ 15-line structured reports. The parent forwards reports verbatim to the user. Auto-dispatch on a Monitor stdout line (`[ui-forge] round=N screen=X ...`) is the right call when the trigger is mechanical and asking for confirmation would break the UX flow.

Key files to study:
- `agents/ui-forge-*.md` — three agent definitions sharing the same skeleton: lock-in line, inputs contract, files-to-read list, precedence rules, output contract, structured report format.
- `skills/ui-forge/SKILL.md` § Subagents — table mapping each phase to its dispatcher and writes; § Phase 2/3/4 — how the main session invokes each agent.
- `skills/ui-forge/references/subcommands.md` § "On feedback event" — the auto-dispatch contract from Monitor stdout line to Agent call.
