---
name: coordinator-workflow
description: Model-agnostic planner-worker-review workflow for OpenCode coding tasks. Plan with plan-orchestrator, investigate with explore/scout, delegate bounded feature-scoped implementation to one or more fullstack-workers as needed, use repair-worker for bugs/tests/build failures, and optionally use code-reviewer as a costly independent review gate.
license: MIT
compatibility: opencode
metadata:
  workflow: planner-explore-scout-worker-repair-docs-review
  primary-agent: plan-orchestrator
  repo-investigation: explore
  docs-investigation: scout
  default-worker: fullstack-worker
  repair-worker: repair-worker
  docs-maintainer: docs-maintainer
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
9. Use as many implementation workers as necessary when the plan decomposes into independent, precisely scoped features or change-sets.
10. Use `@fullstack-worker` for normal implementation work, with one clear feature scope per worker.
11. Use `@repair-worker` for bugs, tests, lint, typecheck, build, CI failures, and correction loops.
12. Review the worker output and current git diff against the original plan.
13. Use `@docs-maintainer` whenever relevant changes should be captured in README.md, Info/, architecture notes, usage docs, examples, or other durable project documentation.
14. Use `@code-reviewer` only as an optional costly independent review gate for high-risk or user-requested reviews.
15. Request the smallest correction loop if the diff does not satisfy the plan.
16. For multi-phase implementation plans, ensure each phase has a durable Markdown artifact before or during that phase: an ADR for hard-to-reverse decisions, or a phase note for ordinary implementation summaries.
17. Use the coordinator grill-with-docs protocol for major plans, ambiguous domain terms, cross-agent handoffs, and phase transitions so decisions are captured in docs instead of only inferred from git diff.
18. Propose a commit only after the diff satisfies the plan, verification is complete, and relevant docs are updated. If the user explicitly instructs you to commit, the orchestrator may stage only intended files and create the commit itself after inspecting status, diff, and recent history.

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
- Define the phase artifact required for each implementation phase.
- Choose the implementation worker or workers.
- Assign each implementation worker a precise, non-overlapping feature scope.
- Send each worker a coordination packet: goal, phase, phase artifact path, resolved decisions, open questions, and documentation expectations.
- Review the final diff against the original plan.
- Prevent scope creep.
- Decide whether `@docs-maintainer` is required for durable documentation updates.
- Decide whether optional `@code-reviewer` is worth the cost.
- Commit changes when explicitly instructed or after asking for approval, using the commit workflow below.

The orchestrator should prefer planning and review over direct implementation. It should not directly edit source files unless the user explicitly asks or the change is trivial and safe. It may run `git add` / `git commit` only when the user explicitly instructs it to commit, or after it asks and receives approval.

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

Use it for:

- Feature implementation.
- Frontend changes.
- Backend changes.
- Full-stack changes.
- Refactors explicitly requested in the plan.
- Documentation edits.
- Configuration changes.
- Straightforward multi-file edits where the plan is clear.

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

Use it for:

- Bug reproduction.
- Root-cause analysis.
- Smallest-safe bug fixes.
- Regression tests.
- Test additions or repairs.
- Lint failures.
- Typecheck failures.
- Build failures.
- CI-style deterministic failures.
- Correction loops after `@fullstack-worker`.

Worker instructions:

- Start from evidence: failing output, reproduction steps, logs, test names, type errors, or current diff.
- Identify the root cause before editing when feasible.
- Implement the smallest safe fix.
- Do not delete tests, weaken assertions, disable checks, or ignore errors unless explicitly approved.
- Do not opportunistically refactor.
- Stop and report if the failure indicates a broader product or architecture decision.
- Report evidence, root cause, changed files, commands run, validation results, unresolved failures, and risks.

### docs-maintainer

Use `@docs-maintainer` as the documentation, research-note, and repo-docs maintenance worker.

Use it for:

- Updating README.md after user-facing workflow, setup, command, or architecture changes.
- Creating or updating durable notes under `Info/`.
- Capturing relevant research findings, implementation decisions, tradeoffs, and migration notes.
- Updating architecture docs, usage docs, examples, and configuration docs.
- Keeping documentation aligned after `@fullstack-worker` or `@repair-worker` changes.
- Producing concise change summaries that future agents and maintainers can understand.

Documentation worker instructions:

- Prefer updating existing docs over creating duplicates.
- Put durable research notes, implementation summaries, and decisions under `Info/`.
- Keep README.md concise and current; move long explanations to `Info/` or docs folders.
- Preserve model-agnostic wording unless documenting a concrete example config.
- Do not edit application/source code.
- Do not change runtime behavior, tests, package files, schemas, or public contracts.
- Do not invent features, tests, commands, or support guarantees that are not present.
- Stop and report if source changes are required to make the documentation true.
- Report docs changed, Info/ entries created or updated, README changes, commands run, and remaining stale-doc risks.

### code-reviewer

Use `@code-reviewer` only when independent review is worth the extra cost.

Use it for:

- High-risk changes.
- Security-sensitive changes.
- Auth, payments, data, migrations, or permissions work.
- Public API or schema changes.
- Large diffs.
- Release-critical work.
- User-requested second review.

The normal final review can be performed by `@plan-orchestrator`. `@code-reviewer` should be a read-only review gate, not an implementation worker.

Reviewer instructions:

- Review the diff against the original plan.
- Do not edit files.
- Focus on correctness, edge cases, security, performance, maintainability, contract compatibility, and test sufficiency.
- Return concrete findings with severity.
- State whether the implementation stayed within scope.
- Provide the smallest correction prompt when not ready.

## Worker Selection Rule

Default to `@fullstack-worker`.

Use `@repair-worker` when at least one condition is true:

- The request is primarily a bug fix.
- The request is primarily test creation or test repair.
- The request starts from a failing test, lint, typecheck, build, or CI output.
- A previous implementation is close but validation failed.
- The task requires root-cause analysis before editing.
- The orchestrator needs a smallest-safe correction loop.

Use `@docs-maintainer` when at least one condition is true:

- The implementation changes user-facing behavior, setup, commands, architecture, or workflow.
- The task produced durable research findings or dependency decisions.
- README.md is now stale or incomplete.
- New or changed examples/configuration need explanation.
- A change should be summarized under `Info/` for future reference.
- The user explicitly asks to update documentation.

Use `@code-reviewer` only when at least one condition is true:

- The user explicitly asks for independent review.
- The diff is high risk.
- The change touches auth, security, payments, permissions, data integrity, migrations, or public API contracts.
- The diff is large or release-critical.
- The orchestrator is uncertain after its own review.

Do not use `@code-reviewer` for every small change. The orchestrator should review normal diffs itself.

## Phase Artifacts

For any implementation plan with named phases, create or delegate one Markdown artifact per phase. Do this even when the code diff is small, because the phase artifact is the durable coordination record for future agents.

Use this decision rule:

- ADR: use when the phase locks a hard-to-reverse, security-sensitive, runtime, data, dependency, schema, or architecture decision.
- Phase note: use when the phase primarily records implementation scope, validation results, package choices, follow-ups, or handoff context.
- Existing canonical doc update: use when the project already has an explicit phase log, implementation plan, changelog, or milestone file and adding a new standalone note would duplicate it.

The phase artifact should capture:

- Phase name and status.
- Goal and non-goals.
- Decisions made and alternatives rejected.
- Affected surfaces and ownership boundaries.
- Validation run and known gaps.
- Follow-ups before the next phase.
- Worker handoffs and coordination notes that are not obvious from git diff.

Prefer delegating artifact creation/update to `@docs-maintainer`, but the orchestrator remains accountable for ensuring it exists before the phase is marked complete.

## Coordinator Grill-With-Docs Protocol

Use this lightweight adaptation of `grill-with-docs` for plan-orchestrator to worker coordination and user-facing planning. It is the coordinator workflow's built-in decision-capture loop, not a replacement for the standalone skill.

Before major implementation phases, high-risk changes, or ambiguous plans:

1. Look for existing project language and decisions in `CONTEXT.md`, `CONTEXT-MAP.md`, `docs/adr/`, `Info/`, README files, implementation plans, changelogs, and architecture notes.
2. Challenge terms that conflict with existing docs. If a word is overloaded, propose a precise canonical term.
3. Cross-check claims against code or docs when feasible. If code contradicts the plan, surface the contradiction before assigning work.
4. Ask one precise question at a time only when repository exploration cannot answer it.
5. Record resolved decisions in the relevant phase artifact, ADR, `CONTEXT.md`, changelog, or implementation note.
6. Do not treat git diff as the only source of truth. Worker reports, resolved assumptions, and user decisions should become durable notes when they affect future work.

Use `CONTEXT.md` only for glossary/domain language. Do not turn it into a spec or implementation log. Use ADRs or phase notes for implementation decisions.

## Commit Workflow

The orchestrator may commit when explicitly instructed by the user, or after asking for and receiving approval. Workers should not commit unless their own permissions and the user explicitly allow it.

Before committing:

1. Inspect `git status --short`, `git diff`, and `git log --oneline -10` in the correct repository.
2. Confirm the repository boundary when the workspace contains multiple git repos.
3. Stage only the files that belong to the approved change. Never stage unrelated dirty files.
4. Ensure relevant phase artifacts/docs are updated or explicitly deferred.
5. Use a concise commit message matching repository style.

Never amend, push, force-push, reset, clean, checkout, switch, restore, delete files, or run destructive commands unless the user explicitly requests that exact operation and the safety policy allows it.

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

Documentation updates:
- README update needed: yes/no
- Info/ note needed: yes/no
- Other docs/examples update needed: yes/no

Phase artifact:
- Needed: yes/no
- Type: ADR / phase note / existing canonical doc update
- Path:
- Owner: plan-orchestrator / docs-maintainer

Risks:

Delegation targets:
- One or more @fullstack-worker agents for normal implementation, split by precise non-overlapping feature scope when useful
- @repair-worker for bug/test/build/lint/typecheck/CI repair or correction loops
- @docs-maintainer for README, Info/, architecture notes, usage docs, examples, or research summaries
- @code-reviewer only for optional costly independent review

Worker prompt(s):
```

## Delegation Prompt Templates

### Normal implementation

For parallel feature work, create one prompt per `@fullstack-worker`. Each prompt must name the exact feature scope, expected files or boundaries where known, constraints, and verification for that worker. Do not give two workers overlapping ownership unless explicitly coordinating a handoff.

```text
@fullstack-worker Implement the approved plan exactly.

Goal:
[goal]

Feature scope:
[precise non-overlapping feature or change-set assigned to this worker]

Coordination packet:
- Phase:
- Phase artifact path:
- Resolved decisions:
- Open questions:
- Docs/context to respect:
- Docs to update or report back:

Plan:
[steps]

Constraints:
- Do not broaden scope.
- Do not refactor unrelated code.
- Do not change public APIs, schemas, routes, or env contracts unless the plan explicitly requires it.
- Match existing style and project conventions.
- Run the relevant tests or explain why they cannot be run.
- Report changed files, commands run, validation results, unresolved issues, and any decisions or terms that should be captured in the phase artifact.
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

### Documentation maintenance

```text
@docs-maintainer Update documentation for this approved change or research result.

Context:
[what changed / research result / implementation summary]

Coordination packet:
- Phase:
- Phase artifact type/path:
- Decisions to capture:
- Terms/glossary updates needed:
- Follow-ups for next phase:

Documentation scope:
- README.md: [yes/no and what to update]
- Info/: [yes/no and durable note topic]
- Other docs/examples: [yes/no and paths if known]

Constraints:
- Do not edit source/application code.
- Do not change runtime behavior, package files, schemas, tests, or public contracts.
- Prefer updating existing docs over creating duplicates.
- Keep README concise; move detailed notes to Info/ or docs folders.
- Do not invent unsupported features, commands, tests, or guarantees.
- Report docs changed, Info/ entries created or updated, README changes, phase artifact status, commands run, and remaining stale-doc risks.
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

After worker completion, review before asking for or creating a commit:

```text
Review the current git diff against the original plan.

Check:
- Did the implementation satisfy the goal?
- Did it stay within scope?
- Are all changed files justified?
- Are there unrelated refactors or formatting changes?
- Are public contracts unchanged unless planned?
- Are tests added or updated where appropriate?
- Are README.md, Info/, and related docs updated when relevant?
- Does every completed phase have a phase artifact, ADR, or explicit canonical-doc update?
- Were worker coordination decisions captured outside the git diff when they affect future work?
- Were relevant tests run?
- Are there obvious security, correctness, accessibility, performance, or maintainability issues?
- Is the change ready to commit?

If not ready, provide the smallest correction prompt for @fullstack-worker, @repair-worker, or @docs-maintainer.
Use @code-reviewer only if independent review is justified by risk or user request.
```

## Karpathy-Inspired Coding Rules

These rules are adapted from `https://github.com/multica-ai/andrej-karpathy-skills/blob/main/skills/karpathy-guidelines/SKILL.md` and apply to the orchestrator and every delegated worker.

### Think Before Coding

Do not assume silently. Surface uncertainty, assumptions, and tradeoffs before implementation. If multiple interpretations exist, choose the smallest safe path or ask a concise clarifying question.

### Simplicity First

Use the minimum code required. Do not add speculative abstractions, future-proofing, configurability, or unrelated features.

### Surgical Changes

Touch only what the request requires. Do not refactor adjacent code. Match existing style. Remove only unused code introduced by the current change.

### Goal-Driven Execution

Every plan step must have a verification method. Convert bugs into reproducing checks when feasible. Loop until success criteria are met or a blocker is reported.

## Safety Gates

Never silently perform destructive or remote-impacting actions.

Require explicit user approval for:

- `git add *`
- `git commit *`
- `git push *`
- `git checkout *`
- `git switch *`
- `git restore *`
- `rm *`
- `sudo *`

Treat these as normally forbidden unless the user explicitly overrides the workflow:

- `git reset *`
- `git clean *`

## Completion Report

At the end of an implementation/review cycle, report:

```text
Summary:

Changed files:

Verification run:

Phase artifact:
- Path:
- Status:
- Decisions captured:

Documentation updates:
- README.md:
- Info/:
- Other docs:

Result:

Risks / follow-ups:

Independent review:
- Used @code-reviewer: yes/no
- Reason:

Ready to commit: yes/no

Commit:
- Created: yes/no
- Hash:
- Message:

Suggested commit message:
```
