# 2. Independent plugins, not monolithic bundle

**Date:** 2026-03-29
**Status:** accepted (supersedes earlier "unified plugin" approach)

## Context
First iteration bundled everything into forge-keeper as one big plugin. This prevented testing individual skills in isolation and forced an all-or-nothing installation. The real need is a marketplace of independent plugins where each can be installed, tested, and removed individually.

## Decision
Each skill/agent/hook set is an **independent plugin** in `plugins/<name>/`:
- Default is full independence — every plugin works standalone
- Only unify when components are tightly coupled (e.g., forge-keeper's hook + sync skill)
- The marketplace catalog (`marketplace.json`) lists all available plugins
- Users install what they need, remove what they don't
- Dependency map in `docs/dependencies.md` documents relationships

## Consequences
- Easier: test with/without any plugin, gradual adoption, no bloated context
- Easier: clear ownership per plugin, simpler updates from upstream
- Harder: more plugins to manage in marketplace.json
- Trade-off: some duplication of reference files across plugins (acceptable — independence > DRY at plugin level)
