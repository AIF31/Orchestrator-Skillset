---
description: Update README, Info/ notes, and related docs with the docs maintainer
agent: docs-maintainer
---

Use the coordinator-workflow skill.

Update project documentation for the approved change or research result described in the arguments or the previous message.

Constraints:
- Do not edit application or source code.
- Do not change runtime behavior, tests, package files, schemas, or public contracts.
- Prefer updating existing docs over creating duplicates.
- Keep README.md concise; put durable notes under Info/ or docs folders.
- Do not invent unsupported features, commands, tests, or guarantees.
- Report docs changed, Info/ entries created or updated, README changes, commands run, and remaining stale-doc risks.

Task: $ARGUMENTS
