---
# Curated from: anthropics/claude-code (plugins/hookify) — Author: Daisy Hollman (Anthropic)
description: Create hooks to prevent unwanted behaviors from conversation analysis or explicit instructions
argument-hint: Optional specific behavior to address
allowed-tools: ["Read", "Write", "AskUserQuestion", "Task", "Grep", "TodoWrite", "Skill"]
---

# Hookify - Create Hooks from Unwanted Behaviors

**FIRST: Load the hookify:writing-rules skill** using the Skill tool to understand rule file format and syntax.

Create hook rules to prevent problematic behaviors by analyzing the conversation or from explicit user instructions.

## Your Task

### Step 1: Gather Behavior Information

**If $ARGUMENTS is provided:**
- User has given specific instructions: `$ARGUMENTS`
- Analyze recent conversation for additional context

**If $ARGUMENTS is empty:**
- Launch the conversation-analyzer agent to find problematic behaviors

### Step 2: Present Findings to User

Use AskUserQuestion:

**Question 1**: Which behaviors to hookify? (multiSelect: true, max 4 options)
**Question 2**: For each selected — block or warn?
**Question 3**: Pattern refinement

### Step 3: Generate Rule Files

Create `.claude/hookify.{rule-name}.local.md` files:

```markdown
---
name: {rule-name}
enabled: true
event: {bash|file|stop|prompt|all}
pattern: {regex pattern}
action: {warn|block}
---

{Message to show when rule triggers}
```

**IMPORTANT**: Create files in project's `.claude/` directory, NOT the plugin directory.

### Step 4: Confirm

Show what was created and remind: **"Rules are active immediately — no restart needed!"**

## Event Types

- **bash**: Bash tool commands
- **file**: Edit, Write, MultiEdit tools
- **stop**: When agent wants to stop
- **prompt**: When user submits prompts
- **all**: All events
