---
name: coordinator-workflow
description: Model-agnostic planner-worker-review workflow for OpenCode coding tasks. Plan with plan-orchestrator, investigate with explore/scout, delegate bounded implementation to fullstack-worker, use repair-worker for bugs/tests/build failures, and optionally use code-reviewer as a costly independent review gate.
license: MIT
compatibility: opencode
metadata:
  workflow: planner-explore-scout-worker-repair-review
  primary-agent: plan-orchestrator
  repo-investigation: explore
  docs-investigation: scout
  default-worker: fullstack-worker
  repair-worker: repair-worker
  optional-reviewer: code-reviewer
  model-policy: agent names are role-based and model-agnostic; change model fields in opencode config when testing new models
---

# Coordinator Workflow

Use this skill for coding, refactoring, debugging, feature implementation, test repair, build repair, and repository maintenance tasks where planning and controlled delegation reduce risk.

This workflow is intentionally model-agnostic. Agent names describe responsibilities, not providers or model families. To test a new model later, change only the `model` field for the relevant agent in `opencode.json`; do not rename the role unless the responsibility changes.

## Core Workflow

Operate in this loop:

1. Understand the request and identify the smallest useful outcome.
2. Inspect the repository only as much as needed.
3. Use `@explore` for read-only repo discovery when affected files, architecture, existing patterns, or impact radius are unclear.
4. Use `@scout` for read-only external docs, dependency, SDK, framework, or upstream-source research when behavior is version-sensitive.
5. State assumptions, constraints, tradeoffs, and risks.
6. Produce a bounded implementation plan.
7. Define success criteria and verification steps before implementation.
8. Delegate implementation only after the plan is clear and approval has been given, unless the user has already explicitly authorized implementation.
9. Use exactly one implementation worker per change-set.
10. Use `@fullstack-worker` for normal implementation work.
11. Use `@repair-worker` for bugs, tests, lint, typecheck, build, CI failures, and correction loops.
12. Review the worker output and current git diff against the original plan.
13. Use `@code-reviewer` only as an optional costly independent review gate for high-risk or user-requested reviews.
14. Request the smallest correction loop if the diff does not satisfy the plan.
15. Propose a commit only after the diff satisfies the plan and verification is complete.

## Agent Roles

### plan-orchestrator

The orchestrator is the default planning, routing, and final-review agent.

Responsibilities:

- Clarify the goal.
- Inspect only the necessary repository context.
- Decide whether `@explore` or `@scout` is needed.
- Decompose the task.
- Identify affected files.
- Define success criteria.
- Choose the implementation worker.
- Enforce one active implementation worker per change-set.
- Review the final diff against the original plan.
- Prevent scope creep.
- Decide whether optional `@code-reviewer` is worth the cost.

The orchestrator should prefer planning and review over direct implementation. It should not directly edit source files unless the user explicitly asks or the change is trivial and safe.

### explore

Use `@explore` for read-only repository investigation.

Use it for:

- Finding relevant files.
- Understanding module boundaries.
- Mapping entry points and call paths.
- Identifying existing patterns.
- Locating tests and fixtures.
- Estimating impact radius.
- Answering codebase questions without edits.

Do not use `@explore` for implementation.

### scout

Use `@scout` for read-only external docs and dependency investigation.

Use it for:

- Framework behavior.
- SDK/API usage.
- Version-sensitive library details.
- Upstream source patterns.
- Migration notes.
- Browser/runtime behavior.
- Dependency edge cases.

Do not use `@scout` for implementation.

### fullstack-worker

Use `@fullstack-worker` as the default implementation worker.

Use it for feature implementation, frontend changes, backend changes, full-stack changes, planned refactors, documentation edits, configuration changes, and straightforward multi-file edits where the plan is clear.

Worker instructions:

- Implement the plan exactly.
- Do not broaden scope.
- Do not redesign architecture unless explicitly asked.
- Do not refactor unrelated code.
- Match existing code style and project conventions.
- Preserve public contracts unless the plan explicitly changes them.
- Run relevant tests or explain why they cannot be run.
- Report changed files, commands run, validation results, and unresolved issues.

### repair-worker

Use `@repair-worker` as the focused repair, testing, and validation worker.

Use it for bugs, root-cause analysis, smallest-safe bug fixes, regression tests, test additions or repairs, lint failures, typecheck failures, build failures, CI-style deterministic failures, and correction loops after `@fullstack-worker`.

Worker instructions:

- Start from evidence: failing output, reproduction steps, logs, test names, type errors, or current diff.
- Identify the root cause before editing when feasible.
- Implement the smallest safe fix.
- Do not delete tests, weaken assertions, disable checks, or ignore errors unless explicitly approved.
- Do not opportunistically refactor.
- Stop and report if the failure indicates a broader product or architecture decision.
- Report evidence, root cause, changed files, commands run, validation results, unresolved failures, and risks.

### code-reviewer

Use `@code-reviewer` only when independent review is worth the extra cost.

Use it for high-risk changes, security-sensitive changes, auth, payments, data, migrations, permissions, public API/schema changes, large diffs, release-critical work, and user-requested second reviews.

The normal final review can be performed by `@plan-orchestrator`. `@code-reviewer` should be a read-only review gate, not an implementation worker.

## Worker Selection Rule

Default to `@fullstack-worker`.

Use `@repair-worker` when the request is primarily a bug fix, test creation or repair, starts from failing validation output, follows a failed implementation, requires root-cause analysis, or needs a smallest-safe correction loop.

Use `@code-reviewer` only when the user explicitly asks for independent review, the diff is high risk, the change touches sensitive contracts or data, the diff is large or release-critical, or the orchestrator is uncertain after its own review.

## Planning Template

Before implementation, produce:

```text
Goal:

Current behavior:

Desired behavior:

Assumptions:

Relevant context:
- Repo investigation needed: yes/no. If yes, use @explore.
- External docs/dependency investigation needed: yes/no. If yes, use @scout.

Affected files:

Implementation steps:
1. [step] -> verify: [check]
2. [step] -> verify: [check]
3. [step] -> verify: [check]

Tests / verification:

Risks:

Delegation target:
- @fullstack-worker for normal implementation
- @repair-worker for bug/test/build/lint/typecheck/CI repair or correction loops
- @code-reviewer only for optional costly independent review

Worker prompt:
```

## Delegation Prompt Templates

### Normal implementation

```text
@fullstack-worker Implement the approved plan exactly.

Goal:
[goal]

Plan:
[steps]

Constraints:
- Do not broaden scope.
- Do not refactor unrelated code.
- Do not change public APIs, schemas, routes, or env contracts unless the plan explicitly requires it.
- Match existing style and project conventions.
- Run the relevant tests or explain why they cannot be run.
- Report changed files, commands run, validation results, and unresolved issues.
```

### Repair / test / build correction

```text
@repair-worker Fix this focused issue using the smallest safe change.

Evidence:
[failing output / repro / diff / test name / lint/type/build error]

Expected result:
[desired behavior or passing validation]

Constraints:
- Start from the evidence.
- Identify root cause where feasible.
- Do not broaden scope.
- Do not delete tests, weaken assertions, disable checks, or ignore errors unless explicitly approved.
- Match existing style and project conventions.
- Run the relevant validation or explain why it cannot be run.
- Report evidence, root cause, changed files, commands run, validation results, and unresolved risks.
```

### Optional independent review

```text
@code-reviewer Review the current diff against the approved plan.

Plan:
[original plan]

Focus:
- Correctness
- Edge cases
- Security
- Performance
- Maintainability
- Contract compatibility
- Test sufficiency
- Scope control

Return:
- Strengths
- Findings with severity
- File-specific recommendations
- Whether the diff stayed within scope
- Whether the change is ready
- Smallest correction prompt if not ready
```

## Review Template

After worker completion, review before asking for commit:

```text
Review the current git diff against the original plan.

Check:
- Did the implementation satisfy the goal?
- Did it stay within scope?
- Are all changed files justified?
- Are there unrelated refactors or formatting changes?
- Are public contracts unchanged unless planned?
- Are tests added or updated where appropriate?
- Were relevant tests run?
- Are there obvious security, correctness, accessibility, performance, or maintainability issues?
- Is the change ready to commit?

If not ready, provide the smallest correction prompt for @fullstack-worker or @repair-worker.
Use @code-reviewer only if independent review is justified by risk or user request.
```

## Safety Gates

Never silently perform destructive or remote-impacting actions.

Require explicit user approval for `git add *`, `git commit *`, `git push *`, `git checkout *`, `git switch *`, `git restore *`, `rm *`, and `sudo *`.

Treat `git reset *` and `git clean *` as normally forbidden unless the user explicitly overrides the workflow.

## Completion Report

At the end of an implementation/review cycle, report:

```text
Summary:

Changed files:

Verification run:

Result:

Risks / follow-ups:

Independent review:
- Used @code-reviewer: yes/no
- Reason:

Ready to commit: yes/no

Suggested commit message:
```
