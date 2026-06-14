---
description: Run focused test, lint, typecheck, build, or CI repair with the repair worker
agent: repair-worker
---

Use the coordinator-workflow skill.

Fix this deterministic validation or repair task with the smallest safe change, or retry and repair the current approved plan when the default fullstack worker got stuck. Start from evidence, identify the root cause where feasible, run the relevant validation, and report changed files and results.

Use this when:
- validation failed,
- the task is a bug fix,
- the task needs test, lint, typecheck, build, or CI repair,
- or the default fullstack worker got stuck.

Constraints:
- Do not broaden scope or refactor unrelated code.
- Do not delete tests, weaken assertions, disable checks, or ignore errors unless explicitly approved.
- Match existing style and project conventions.
- Report evidence, root cause when known, changed files, commands run, validation results, and unresolved issues.

Task: $ARGUMENTS
