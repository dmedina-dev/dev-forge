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
