---
# Curated from: anthropics/claude-code (plugins/plugin-dev) — Author: Daisy Hollman (Anthropic)
name: Skill Development
description: This skill should be used when the user wants to "create a skill", "add a skill to plugin", "write a new skill", "improve skill description", "organize skill content", or needs guidance on skill structure, progressive disclosure, or skill development best practices for Claude Code plugins.
version: 0.1.0
---

# Skill Development for Claude Code Plugins

This skill provides guidance for creating effective skills for Claude Code plugins.

## About Skills

Skills are modular, self-contained packages that extend Claude's capabilities by providing specialized knowledge, workflows, and tools. Think of them as "onboarding guides" for specific domains or tasks.

### What Skills Provide

1. Specialized workflows - Multi-step procedures for specific domains
2. Tool integrations - Instructions for working with specific file formats or APIs
3. Domain expertise - Company-specific knowledge, schemas, business logic
4. Bundled resources - Scripts, references, and assets for complex and repetitive tasks

### Anatomy of a Skill

```
skill-name/
├── SKILL.md (required)
│   ├── YAML frontmatter metadata (required)
│   │   ├── name: (required)
│   │   └── description: (required)
│   └── Markdown instructions (required)
└── Bundled Resources (optional)
    ├── scripts/          - Executable code (Python/Bash/etc.)
    ├── references/       - Documentation loaded into context as needed
    └── assets/           - Files used in output (templates, icons, fonts, etc.)
```

#### Progressive Disclosure Design Principle

Skills use a three-level loading system to manage context efficiently:

1. **Metadata (name + description)** - Always in context (~100 words)
2. **SKILL.md body** - When skill triggers (<5k words)
3. **Bundled resources** - As needed by Claude (Unlimited)

## Skill Creation Process

### Step 1: Understanding the Skill with Concrete Examples

Clearly understand concrete examples of how the skill will be used. Ask questions like:
- "What functionality should this skill support?"
- "Can you give examples of how it would be used?"
- "What would a user say that should trigger this skill?"

### Step 2: Planning the Reusable Skill Contents

Analyze each example by:
1. Considering how to execute on the example from scratch
2. Identifying what scripts, references, and assets would be helpful when executing these workflows repeatedly

### Step 3: Create Skill Structure

```bash
mkdir -p plugin-name/skills/skill-name/{references,examples,scripts}
touch plugin-name/skills/skill-name/SKILL.md
```

### Step 4: Edit the Skill

**Writing Style:** Write using **imperative/infinitive form** (verb-first instructions), not second person.

**Description (Frontmatter):** Use third-person format with specific trigger phrases:

```yaml
---
name: Skill Name
description: This skill should be used when the user asks to "specific phrase 1", "specific phrase 2". Include exact phrases users would say that should trigger this skill.
---
```

**Keep SKILL.md lean:** Target 1,500-2,000 words for the body. Move detailed content to references/.

### Step 5: Validate and Test

1. **Check structure**: Skill directory in `plugin-name/skills/skill-name/`
2. **Validate SKILL.md**: Has frontmatter with name and description
3. **Check trigger phrases**: Description includes specific user queries
4. **Verify writing style**: Body uses imperative/infinitive form, not second person
5. **Test progressive disclosure**: SKILL.md is lean, detailed content in references/
6. **Check references**: All referenced files exist

**Use the skill-reviewer agent** for automated review.

### Step 6: Iterate

After testing the skill, identify improvements:
- Strengthen trigger phrases in description
- Move long sections from SKILL.md to references/
- Add missing examples or scripts
- Clarify ambiguous instructions

## Plugin-Specific Considerations

### Auto-Discovery

Claude Code automatically discovers skills:
- Scans `skills/` directory
- Finds subdirectories containing `SKILL.md`
- Loads skill metadata (name + description) always
- Loads SKILL.md body when skill triggers
- Loads references/examples when needed

### Testing in Plugins

```bash
cc --plugin-dir /path/to/plugin
```

## Common Mistakes to Avoid

### Weak Trigger Description
```yaml
# Bad: description: Provides guidance for working with hooks.
# Good: description: This skill should be used when the user asks to "create a hook", "add a PreToolUse hook"...
```

### Too Much in SKILL.md
Keep under 3,000 words, ideally 1,500-2,000. Move details to references/.

### Second Person Writing
Use imperative form: "Create a hook" not "You should create a hook".

## Validation Checklist

- [ ] SKILL.md file exists with valid YAML frontmatter
- [ ] Frontmatter has `name` and `description` fields
- [ ] Description uses third person with specific trigger phrases
- [ ] Body uses imperative/infinitive form
- [ ] Body is focused and lean (1,500-2,000 words ideal)
- [ ] Detailed content moved to references/
- [ ] Examples are complete and working
- [ ] Scripts are executable and documented
