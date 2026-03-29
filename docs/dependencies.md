# Plugin Dependency Map

Which plugins depend on or complement each other.

## Legend

- **requires** — won't work without the other plugin
- **complements** — works better together but each is functional alone
- **independent** — no relationship

## Current plugins

### forge-init
- **Independent** — standalone bootstrapper, no dependencies
- Mentions forge-keeper in cleanup message but doesn't require it

### forge-keeper
- **Self-contained** — hooks + skills + scripts form a cohesive unit
- The context-watch hook, sync/status/optimize commands, and references are tightly coupled
- This is an example of justified unification: splitting hook from skill would break the workflow

## Future plugins (to be populated as plugins are added)

```
Plugin              Requires        Complements         Independent of
─────────────────────────────────────────────────────────────────────
forge-init          -               forge-keeper        everything else
forge-keeper        -               forge-init          everything else
forge-agents        -               -                   everything
forge-tdd           -               forge-agents        everything else
```

## Rules for dependencies

1. **Default is independent** — design plugins to work alone
2. **If you need another plugin**, document it here AND in the plugin's SKILL.md description
3. **Complements** are soft — mention in docs but don't enforce
4. **Requires** are hard — plugin should warn at activation if dependency is missing
