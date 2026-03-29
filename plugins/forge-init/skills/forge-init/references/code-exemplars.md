# Code Exemplars — Identification Process

Reference for forge-init step 2.6. Use this when identifying code exemplars
with the human during project initialization.

## What are exemplars

Files that best represent how things should be done in this project.
Projects evolve through patterns — old code coexists with new conventions.
Exemplars mark the target, not the average.

## Interview the human

Ask:

"Let's identify the cleanest examples in your codebase — files that show
the way things should be done going forward. For each area, which file
would you point a new developer to as the reference?"

## Categories to explore

Adapt to the project's stack. Not every category applies:

- **Controller/route handler** — the cleanest endpoint implementation
- **Service/use case** — the best business logic organization
- **Domain entity** — the model others should follow
- **Test file** — the best-structured test suite
- **Component** (if frontend) — the reference UI component
- **Migration/schema** — the clearest DB change
- **Event handler** — the cleanest async/event processing
- **CLI command** — the best-organized command implementation

If no clean example exists for a category, skip it. Don't force it.

## What to capture per exemplar

For each file the human identifies:
- **File path** — exact path to the file
- **Pattern** — what convention or approach this file demonstrates
- **Why exemplary** — what makes it the reference vs other files in the same
  category (cleaner structure, better naming, proper error handling, etc.)

## Storage format

Create `docs/exemplars.md`:

```markdown
# Code Exemplars

Reference files that demonstrate the target patterns for this project.
When writing new code, use these as your model.

## [Category]
- **File:** `path/to/file.ts`
- **Pattern:** [what this file demonstrates]
- **Why exemplary:** [what makes it the reference vs alternatives]
```

Add an @import in root CLAUDE.md:
```
For code exemplars see @docs/exemplars.md
```

## Key principles

- Exemplars are living documents — session-keeper evaluates them after changes
- Fewer exemplars is better than many — only the truly clean ones
- Exemplars should represent the target direction, not legacy patterns
- If the whole project is transitioning, pick from the new-pattern code
