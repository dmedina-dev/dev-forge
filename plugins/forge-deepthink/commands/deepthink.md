---
description: Run the deep-think protocol on a prompt — pre-filled 7-slot interview, audit-ready response with visible reasoning, red-teaming, pre-mortem, and assumption audit. Stays active the rest of the session.
argument-hint: [your prompt — optional]
---

The user has invoked `/deepthink`. Activate the deep-think protocol now by invoking the `forge-deepthink:deep-think` skill via the `Skill` tool.

User's prompt for deep-think (may be empty if the user invoked `/deepthink` alone — in that case, ask them what they want to deep-think about):

$ARGUMENTS

The protocol stays active for the rest of the session unless the user explicitly says "exit deepthink", "vuelve a modo normal", or equivalent. Do not require the user to repeat `/deepthink` in follow-up turns — keep applying the protocol until told otherwise.
