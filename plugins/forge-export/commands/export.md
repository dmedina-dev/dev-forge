---
description: Export this dev-forge marketplace into a new standalone marketplace repository. Runs an interview to select plugins, resolve customizations, and write the complete output structure.
---

Run the forge-export skill to export this marketplace into a new standalone repository.

This is a guided interview-driven process:

Interview — Understand intent:
  Collect the target repo name, author info, and any high-level preferences
  about what should be included or excluded.

Detection — Catalog available plugins:
  Scan the marketplace and all plugins/ directories to build a complete
  inventory of what can be exported.

Selection — Choose what goes:
  Walk through each plugin interactively. For external plugins, surface
  customizations.json so you can decide which local changes to carry over.

Generation — Write the output:
  Produce the complete standalone repository structure: marketplace.json,
  plugin directories, CLAUDE.md, and any supporting docs.

All decisions require your explicit approval before files are written.

After export, uninstall this plugin:
  /plugin → Manage and uninstall plugins → forge-export → Uninstall
