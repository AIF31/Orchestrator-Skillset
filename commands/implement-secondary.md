---
description: Retry or repair the current plan with the focused repair worker
agent: repair-worker
---

Use the coordinator-workflow skill.

Retry or repair the current approved plan exactly using the focused model-agnostic repair worker path.

Use this only when:
- validation failed,
- the task is a bug fix,
- the task needs test, lint, typecheck, build, or CI repair,
- or the default fullstack worker got stuck.

Constraints:
- Do not broaden scope.
- Do not refactor unrelated code.
- Match existing style and project conventions.
- Run relevant validation when feasible.
- Report evidence, root cause when known, changed files, commands run, validation results, and unresolved issues.
