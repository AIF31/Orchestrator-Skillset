---
description: Run optional costly independent review of the current diff or requested files
agent: code-reviewer
---

Use the coordinator-workflow skill.

Review the active diff or the requested files. Do not edit anything. Focus on correctness, edge cases, security, public contracts, migrations, performance, maintainability, test sufficiency, and scope control. Return concrete findings with severity and the smallest recommended fix, state whether the change stayed in scope, and say whether it is ready.

Request: $ARGUMENTS
