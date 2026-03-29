---
# Curated from: anthropics/claude-code (plugins/plugin-dev) — Author: Daisy Hollman (Anthropic)
name: Plugin Settings
description: This skill should be used when the user wants to configure "plugin settings", ".local.md files", "YAML frontmatter", "plugin configuration", or needs guidance on user-configurable settings patterns for Claude Code plugins.
version: 0.1.0
---

# Plugin Settings Pattern for Claude Code

Plugins can store user-configurable settings using `.claude/plugin-name.local.md` files with YAML frontmatter and markdown content.

## File Structure

- **Location:** `.claude/plugin-name.local.md` in project root
- **Format:** YAML frontmatter (between `---` markers) plus optional markdown body
- **Lifecycle:** User-managed, excluded from version control

## Example Settings File

```markdown
---
enabled: true
model: sonnet
max-retries: 3
---

# Additional notes

Custom instructions or overrides for this plugin.
```

## Parsing Patterns

### Extracting Frontmatter

```bash
SETTINGS_FILE="$CLAUDE_PROJECT_DIR/.claude/plugin-name.local.md"

if [ ! -f "$SETTINGS_FILE" ]; then
  # Use defaults
  exit 0
fi

FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$SETTINGS_FILE")
```

### Reading Individual Fields

```bash
VALUE=$(echo "$FRONTMATTER" | grep '^field:' | sed 's/field: *//')
```

### Quick-Exit Pattern for Hooks

```bash
# Check file exists and feature is enabled before running logic
SETTINGS="$CLAUDE_PROJECT_DIR/.claude/plugin-name.local.md"
[ -f "$SETTINGS" ] || exit 0

ENABLED=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$SETTINGS" | grep '^enabled:' | sed 's/enabled: *//')
[ "$ENABLED" = "true" ] || exit 0

# Proceed with hook logic...
```

## Best Practices

- Provide sensible defaults when settings file doesn't exist
- Always add `.claude/*.local.md` to `.gitignore`
- Validate user input and file paths to prevent injection
- Use consistent naming matching the plugin name exactly
- Document all available settings in plugin README
- Changes to settings require a Claude Code restart (hooks cannot be hot-reloaded)

## Use Cases

- Multi-agent configuration (model selection, behavior flags)
- Temporary hook activation/deactivation
- Per-project plugin behavior customization
- User preferences (output format, verbosity)
