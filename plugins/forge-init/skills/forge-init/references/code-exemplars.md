# Code Exemplars — Identification Process

Reference for forge-init step 6. Use this when identifying code exemplars
with the human during project initialization.

## What are exemplars

Pointers to actual files in the codebase that best represent how things
should be done. Projects evolve through patterns — old code coexists with
new conventions. Exemplars mark the target, not the average.

Exemplars are NOT copies. They point to the real file and describe the
lesson it teaches. Claude reads the actual file when working in that area.

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
- **Configuration** — the cleanest config file (docker, CI, etc.)
- **Event handler** — the cleanest async/event processing

If no clean example exists for a category, skip it. Don't force it.

## What to capture per exemplar

For each file the human identifies:
- **File path** — exact path to the real file (Claude will read it on demand)
- **Pattern** — what convention or approach this file demonstrates
- **Lesson** — what makes it exemplary, what decision or approach it teaches

The lesson is the key differentiator from a simple file listing. It captures
the WHY — why this file is the reference, what would be lost if someone
wrote it differently.

## Storage format

Create `docs/exemplars.md`:

```markdown
# Code Exemplars

Reference files that demonstrate the target patterns for this project.
When writing new code, use these as your model — read the actual file.

## [Category]
- **File:** `path/to/file.ts`
- **Pattern:** [what this file demonstrates]
- **Lesson:** [what decision/approach it teaches and why it matters]
```

Add an @import in root CLAUDE.md:
```
For code exemplars see @docs/exemplars.md
```

## Key principles

- Exemplars are pointers + lessons, not copies
- Fewer exemplars is better than many — only the truly clean ones
- Exemplars should represent the target direction, not legacy patterns
- If the whole project is transitioning, pick from the new-pattern code
- forge-keeper evaluates exemplar freshness after changes
