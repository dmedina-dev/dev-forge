# 2. Unified plugin architecture

**Date:** 2026-03-29
**Status:** accepted

## Context
Initially dev-forge was designed as a marketplace with two plugins (forge-init + forge-keeper). In practice, the goal is a single curated plugin that aggregates skills from multiple sources (superpowers, anthropic official, custom) so the user only needs one plugin installed across all projects.

## Decision
Dev-forge becomes a personal unified plugin collection:
- forge-keeper is the main permanent plugin containing all curated skills, agents, hooks
- forge-init stays separate because it's disposable (install → bootstrap → uninstall)
- Skills from external sources are curated into forge-keeper, adapted to personal preferences
- No need to install superpowers, skill-creator, etc. separately

## Consequences
- Easier: one plugin to manage, one place to customize, updates propagate everywhere
- Harder: must manually track upstream changes in superpowers/anthropic skills
- Trade-off: forge-keeper's context footprint grows with more skills (mitigate with progressive disclosure)
