# docs/glossary.md Format

The glossary captures the **domain language** of the project — the terms that mean something specific in *this* project's context. It is read by every future contributor (human or AI) before they touch the code.

It does **not** capture general programming concepts, file paths, or anything you could derive from the code.

## Structure

```md
# {Project / Zone Name} Glossary

{One or two sentence description of what this glossary covers.}

## Terms

**Order**:
A request from a Customer to receive Goods or Services. Created when the cart is checked out.
_Avoid_: Purchase, transaction.

**Invoice**:
A request for payment sent to a Customer after a Fulfillment is confirmed.
_Avoid_: Bill, payment request.

**Customer**:
A person or organization that places Orders. Distinct from User (who logs into the system).
_Avoid_: Client, buyer, account.

## Relationships

- An **Order** produces one or more **Invoices** (one per Fulfillment).
- An **Invoice** belongs to exactly one **Customer**.
- A **Customer** may have many **Users** (e.g. a company with multiple buyers).

## Example dialogue

> **Dev:** "When a **Customer** places an **Order**, do we create the **Invoice** immediately?"
> **Domain expert:** "No — an **Invoice** is only generated once a **Fulfillment** is confirmed."

## Flagged ambiguities

- "account" was used to mean both **Customer** and **User** — resolved: these are distinct concepts.
- "purchase" was used as a synonym for **Order** — resolved: prefer **Order**.
```

## Rules

- **Be opinionated.** When multiple words exist for the same concept, pick the best one and list the others as aliases to avoid.
- **Flag conflicts explicitly.** If a term is used ambiguously, call it out under "Flagged ambiguities" with the resolution.
- **Keep definitions tight.** One sentence max. Define what it IS, not what it does.
- **Show relationships and cardinality.** Use bold term names; use phrases like "one or more", "exactly one", "may have many".
- **Only domain-specific terms.** Before adding a term, ask: is this concept unique to this project's domain, or just general programming? Only the former belongs.
- **Group under subheadings** when natural clusters emerge. If all terms cohere around one area, a flat list is fine.
- **Write an example dialogue.** A short conversation between a developer and a domain expert that demonstrates how the terms interact and clarifies boundaries.

## Where to place the glossary

**Single-domain repo (most projects):** one `docs/glossary.md` at the repo root.

**Zoned repo:** if the project has clearly distinct domain areas under `src/<zone>/` and each has its own `CLAUDE.md`, you may add a per-zone `src/<zone>/glossary.md` and keep `docs/glossary.md` for terms that span the whole project. Don't split prematurely — only when terms genuinely diverge between zones.

## When to create

Lazily. Only when the first non-trivial domain term is resolved during a grilling session. An empty or skeleton glossary adds noise without value.

## Glossary vs CLAUDE.md

| Belongs in `docs/glossary.md` | Belongs in `CLAUDE.md` |
|-------------------------------|------------------------|
| Domain terms and aliases | Project commands (build, test, deploy) |
| Relationships between concepts | Architecture overview |
| Flagged ambiguities | Conventions to follow |
| Example domain dialogue | Gotchas and workarounds |

CLAUDE.md is line-limited (~200 root, ~100 child) and read on every session start. Keep it for what *every* session needs. Glossary is loaded when domain language matters.
