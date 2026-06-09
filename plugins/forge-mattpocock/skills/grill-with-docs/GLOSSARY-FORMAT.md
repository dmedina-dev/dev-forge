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
```

## Rules

- **Be opinionated.** When multiple words exist for the same concept, pick the best one and list the others under `_Avoid_`.
- **Keep definitions tight.** One or two sentences max. Define what it IS, not what it does.
- **Only domain-specific terms.** Before adding a term, ask: is this concept unique to this project's domain, or just general programming? Only the former belongs.
- **Group under subheadings** when natural clusters emerge. If all terms cohere around one area, a flat list is fine.

## Where to place the glossary

**Single-domain repo (most projects):** one `docs/glossary.md` at the repo root.

**Zoned repo:** if the project has clearly distinct domain areas under `src/<zone>/` and each has its own `CLAUDE.md`, you may add a per-zone `src/<zone>/glossary.md` and keep `docs/glossary.md` for terms that span the whole project. Don't split prematurely — only when terms genuinely diverge between zones.

## When to create

Lazily. Only when the first non-trivial domain term is resolved during a grilling session. An empty or skeleton glossary adds noise without value.

## Glossary vs CLAUDE.md

| Belongs in `docs/glossary.md` | Belongs in `CLAUDE.md` |
|-------------------------------|------------------------|
| Domain terms and `_Avoid_` aliases | Project commands (build, test, deploy) |
| Tight domain definitions | Architecture overview |
| Term groupings by domain area | Conventions, gotchas and workarounds |

CLAUDE.md is line-limited (~200 root, ~100 child) and read on every session start. Keep it for what *every* session needs. Glossary is loaded when domain language matters.
