---
name: coordinator-workflow
description: Model-agnostic planner-worker-review workflow for OpenCode coding tasks. Plan with plan-orchestrator, investigate with explore/scout, delegate bounded feature-scoped implementation to one or more fullstack-workers as needed, use repair-worker for bugs/tests/build failures, and optionally use code-reviewer as a costly independent review gate.
license: MIT
compatibility: opencode
metadata:
  workflow: planner-explore-scout-worker-repair-docs-review
  primary-agent: plan-orchestrator
  repo-investigation: explore
  graph-investigation: graphify-out (used by explore when present and verified fresh via git commits)
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
3. Use `@explore` for read-only repo discovery when affected files, architecture, existing patterns, or impact radius are unclear. If the project carries a verified, up-to-date `graphify-out/` knowledge graph, `@explore` should query it first (see Graphify Graph-First Exploration) and fall back to file scanning only when the graph is absent or stale.
4. Use `@scout` for read-only external docs, dependency, SDK, framework, or upstream-source research when behavior is version-sensitive.
5. State assumptions, constraints, tradeoffs, and risks.
6. Produce a bounded implementation plan.
7. Define success criteria and verification steps before implementation.
8. Decompose the approved plan into an ordered slice list before delegating. Each slice is one concern, independently verifiable, with its own verification step. Never hand a worker the whole plan in a single pass (see Plan Slicing And Incremental Delegation).
9. Delegate implementation only after the plan is sliced and approval has been given, unless the user has already explicitly authorized implementation. Seed the Session Context Brief from the plan before the first delegation, and pass it to workers by reference (see Session Context Brief).
10. Delegate one slice per `@fullstack-worker` invocation, and require the worker to apply the Karpathy-Inspired Coding Rules to that slice. Wait for the worker's report and verify the slice against its own check before releasing the next slice.
11. Maintain a slice checklist (pending / in-progress / done / failed) and update it as slices complete, so progress survives context loss. After each worker report, refresh the Session Context Brief and promote any durable items to `Info/`/ADR.
12. Use `@repair-worker` for bugs, tests, lint, typecheck, build, CI failures, slice verification failures, and correction loops.
13. Use multiple implementation workers in parallel only when slices belong to provably independent, non-overlapping feature scopes.
14. Review the worker output and current git diff against the plan after each slice and again at the end.
15. Use `@docs-maintainer` whenever relevant changes should be captured in README.md, Info/, architecture notes, usage docs, examples, or other durable project documentation.
16. Use `@code-reviewer` only as an optional costly independent review gate for high-risk or user-requested reviews.
17. Request the smallest correction loop if a slice or the final diff does not satisfy the plan.
18. For multi-phase implementation plans, ensure each phase has a durable Markdown artifact before or during that phase: an ADR for hard-to-reverse decisions, or a phase note for ordinary implementation summaries.
19. Use the coordinator grill-with-docs protocol for major plans, ambiguous domain terms, cross-agent handoffs, and phase transitions so decisions are captured in docs instead of only inferred from git diff.
20. Propose a commit only after the diff satisfies the plan, verification is complete, and relevant docs are updated. If the user explicitly instructs you to commit, the orchestrator may stage only intended files and create the commit itself after inspecting status, diff, and recent history.

## Agent Roles

### plan-orchestrator

The orchestrator is the default planning, routing, and final-review agent.

Responsibilities:

- Clarify the goal.
- Inspect only the necessary repository context.
- When `graphify-out/` is present, read `graphify-out/GRAPH_REPORT.md` for a quick orientation pass (key concepts and connections) before broad file reading, to save context.
- Decide whether `@explore` or `@scout` is needed.
- Decompose the task.
- Identify affected files.
- Define success criteria.
- Define the phase artifact required for each implementation phase.
- Author the Master Plan / top-level strategic plan document yourself when asked to write one. Do not delegate it to `@docs-maintainer`: you already hold the full planning context, so writing it directly avoids forcing a cold agent to re-derive it. Continue to use `@docs-maintainer` for README, `Info/` notes, and ordinary per-phase notes.
- Choose the implementation worker or workers.
- Assign each implementation worker a precise, non-overlapping feature scope.
- Send each worker a coordination packet: goal, phase, phase artifact path, resolved decisions, open questions, and documentation expectations.
- Seed the Session Context Brief after planning and refresh it as work proceeds: after each worker report, infer the salient changes (resolved decisions, completed slice, new open questions, follow-ups) and fold them into the brief. Promote `Promotion Candidates` to `Info/`/ADR per the promotion criterion.
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

#### Graphify Graph-First Exploration

If the project carries a `graphify-out/` knowledge graph (produced by the `graphify` skill, `https://github.com/safishamsi/graphify`), `@explore` should treat a *verified, up-to-date* graph as the first lookup surface before falling back to grep/file reads. The graph answers "what connects to what", call paths, and impact radius far faster than scanning files.

Detection and verification gate (run read-only, in order):

1. **Detect.** Look for a `graphify-out/` directory at the project root containing `graph.json` (the full queryable graph), `GRAPH_REPORT.md` (key concepts, connections, suggested questions), and usually `manifest.json` (tracked source files, relative paths) and `graph.html`. If `graph.json` is absent, skip graphify and explore normally.
2. **Verify freshness via git commits.** Trust the graph only when at least one holds:
   - A graphify post-commit auto-rebuild hook is installed (`graphify hook install` adds a post-commit hook that rebuilds `graph.json` from the AST on every commit at no API cost; check for it in `.git/hooks/post-commit` or the repo's git config), **or**
   - The last commit touching `graphify-out/graph.json` is at or newer than the last commit touching tracked source. A practical check: `git log -1 --format=%cI -- graphify-out/graph.json` versus `git log -1 --format=%cI -- <source dirs>`. If source has commits newer than the graph, the graph is stale.
   - Also treat the graph as stale if `graph.json` has unresolved merge-conflict markers, or if `git status` shows large uncommitted source changes not yet reflected in the graph.
3. **Use when fresh.** Query the graph instead of grepping:
   - `graphify query "what connects auth to the database?"` (add `--graph graphify-out/graph.json` to target a specific graph)
   - `graphify path "UserService" "DatabasePool"` for call/dependency paths
   - `graphify explain "RateLimiter"` for a node's role and neighbors
   - Read `graphify-out/GRAPH_REPORT.md` for an orientation pass and suggested questions
   - If the project exposes the graph as an MCP server (`python -m graphify.serve graphify-out/graph.json`), prefer its structured tools (`query_graph`, `get_node`, `get_neighbors`, `shortest_path`) when available.
4. **Fall back when stale or absent.** If the graph fails the freshness gate, do normal file-based exploration and explicitly flag the staleness in the explore report (e.g. "graphify-out/ present but stale — last built before recent source commits; recommend `/graphify . --update` or `/graphify .`"). Never silently trust a stale graph, and never run a rebuild as part of read-only exploration — surface the recommendation to the orchestrator instead.

A graph that a worker just refreshed with `graphify update .` during the current session is fresh for in-session orientation even before the change is committed: the per-slice refresh keeps the working-tree graph current between commits, so the orchestrator and the next worker can trust `GRAPH_REPORT.md` without re-running the git-commit freshness gate. The git-commit gate above still governs a graph inherited from a prior session.

Always corroborate graph claims against the actual files before they drive an edit; the graph accelerates discovery but the working tree remains the source of truth.

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

- Implement only the single slice assigned to you. Do not start slices that were not delegated.
- Apply the Karpathy-Inspired Coding Rules to the slice: think before coding, simplicity first, surgical changes, goal-driven execution.
- Do not broaden scope.
- Do not redesign architecture unless explicitly asked.
- Do not refactor unrelated code.
- Match existing code style and project conventions.
- Preserve public contracts unless the slice explicitly changes them.
- When `graphify-out/` is present, you may read `graphify-out/GRAPH_REPORT.md` (or run `graphify query`/`graphify explain`) to orient on impact radius cheaply instead of scanning many files, keeping your context small. The working tree remains the source of truth.
- Run the slice's own verification, or explain why it cannot be run.
- After the slice's verification passes (slice successful and completed), if `graphify-out/` exists at the repo root, run `graphify update .` to refresh the knowledge graph and `GRAPH_REPORT.md` (AST-only, no LLM cost). Skip it silently when `graphify-out/` is absent; never build a graph from scratch.
- Report changed files, commands run, the slice verification result, whether `graphify update .` ran, and unresolved issues.

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
- When `graphify-out/` is present, you may read `graphify-out/GRAPH_REPORT.md` (or run `graphify query`/`graphify explain`) to orient on impact radius cheaply instead of scanning many files, keeping your context small. The working tree remains the source of truth.
- Stop and report if the failure indicates a broader product or architecture decision.
- After the fix is validated, if `graphify-out/` exists at the repo root, run `graphify update .` to refresh the knowledge graph and `GRAPH_REPORT.md` (AST-only, no LLM cost). Skip it silently when `graphify-out/` is absent; never build a graph from scratch.
- Report evidence, root cause, changed files, commands run, validation results, whether `graphify update .` ran, unresolved failures, and risks.

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
- Do not author the Master Plan / top-level strategic plan document — the orchestrator owns that. Maintain README, `Info/`, examples, architecture/usage docs, and ordinary phase notes around it.
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

## Deep Planning Escalation (Optional)

For the kickoff of a large or high-stakes project, an optional heavyweight
planning agent can create the master plan before the normal loop begins. This is
an escalation layer, not part of the default workflow.

- The deep-planning agent (example: `plan-architect`, backed by a multi-model
  deliberation model) is read-only on product code. It creates, discusses, and
  redlines a **detailed but general** strategic plan: chosen architecture,
  rejected alternatives, a module/seam map, ordered phases, risks, and a
  verification strategy. It deliberately stops at **phase granularity**.
- It does **not** slice, assign workers, or implement. It writes exactly one
  durable plan artifact (an ADR under `docs/adr/` for hard-to-reverse decisions,
  otherwise a phase note under `Info/`) ending with a Plan Handoff Packet, then
  hands off to `@plan-orchestrator`.
- `@plan-orchestrator` **ingests** that artifact as the approved strategic plan
  instead of re-planning: it validates the plan against the current tree,
  decomposes each phase into slices, assigns workers using the Plan Handoff
  Packet's routing intent, and runs the normal slice -> worker -> review loop. Slicing and
  per-slice worker assignment remain the orchestrator's job. Ingestion applies
  only to an explicit handoff for the current request: an ordinary ADR or phase
  note from a prior or unrelated effort is background context, never an approved
  plan that overrides the user's current task.
- Use this only when multi-model critique is worth the extra cost (architecture
  decisions, conflicting external docs, security/data/migration-heavy designs,
  release-critical kickoffs). Avoid it for routine features, small changes, and
  deterministic repair.

The escalation agent is provider-specific by nature; keep it optional and out of
the default config. See `Info/FUSION_PLANNING_AGENT.md` and
`examples/opencode.fusion-planning-agent.jsonc` for a concrete example.

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

## Plan Slicing And Incremental Delegation

Do not hand `@fullstack-worker` an entire implementation plan in one pass. Large single-pass handoffs cause scope drift, conflicting diffs, oversized worker context, and unverifiable changes. Decompose the approved plan and deliver it as a sequence of small, verified slices.

### What a slice is

A slice is the smallest change that is independently verifiable:

- One concern only (one behavior, one fix, one cohesive unit).
- Has its own explicit verification step: a command, test, or concrete check.
- Is surgical: it touches only what that concern requires, per the Karpathy-Inspired Coding Rules.
- Leaves the working tree in a coherent state when complete.

Prefer many small slices over a few large ones. If a slice cannot state its own verification, it is too big or too vague — split it further.

### The incremental loop

1. After the plan is approved, decompose it into an ordered slice list (see the Planning Template's slice plan block).
2. Maintain a slice checklist with a status per slice: pending, in-progress, done, or failed.
3. Delegate exactly one slice to `@fullstack-worker` using the single-slice delegation template. The slice prompt must invoke the Karpathy-Inspired Coding Rules.
4. When the worker reports back, verify the slice against its own check before doing anything else.
5. If the slice passes, mark it done and delegate the next slice. If it fails, mark it failed and route a smallest-correction loop to `@repair-worker` before continuing.
6. Repeat until every slice is done, then run the final review against the original plan.

Each slice is a fresh, bounded worker invocation. This keeps worker context small and makes every change reviewable in isolation.

### Sequencing and parallelism

- Default to sequential delivery with a verification gate between slices.
- Order slices so each builds on a verified base: foundations, types, and contracts before their consumers.
- Use parallel workers only when slices belong to provably independent, non-overlapping feature scopes (see the parallel delegation template). When in doubt, stay sequential.

### Slice checklist format

```text
Slice plan:
1. [slice concern] -> verify: [check] -> status: done
2. [slice concern] -> verify: [check] -> status: in-progress
3. [slice concern] -> verify: [check] -> status: pending
```

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

Prefer delegating artifact creation/update to `@docs-maintainer`, but the orchestrator remains accountable for ensuring it exists before the phase is marked complete. The exception is the **Master Plan / top-level strategic plan** document: the orchestrator authors that itself (it already holds the planning context) and does not delegate it. Delegation to `@docs-maintainer` still applies to README, `Info/` research notes, and ordinary per-phase notes.

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

## Session Context Brief

The Session Context Brief is a single, orchestrator-owned working document that carries shared context **within the current session**. It is a context *feed*, not a durable record: it borrows its document shape from a handoff document (summary, references-not-duplication, redacted secrets, suggested skills) but exists only to brief in-flight workers, not to resume a future session. It is distinct from the Plan Handoff Packet (the plan-architect -> plan-orchestrator strategic handoff). The word "handoff" never refers to this brief.

### Storage and ownership

- **Owner:** `@plan-orchestrator`. No worker writes or owns the brief.
- **Location:** the OS temp directory, e.g. `${TMPDIR:-/tmp}/coordinator-brief-<task-slug>.md`. It is ephemeral by design — its lifetime is the task, and it is expected to disappear when the session ends. Durable content is promoted to `Info/`/ADR (see below), never left only in the brief.
- **Redaction:** never write secrets, API keys, tokens, or PII into the brief. Reference their location instead.

### Canonical sections (stable headings)

The brief uses these exact headings so a coordination packet can name `Read sections:` precisely. Workers read only the sections they are pointed to.

- `Current Slice` — the slice in flight: its concern, scope, and verification.
- `Resolved Decisions` — settled choices that constrain implementation.
- `Relevant References` — paths/URLs to PRDs, ADRs, `Info/` notes, and key files (linked, not duplicated).
- `Open Questions` — unresolved items, each with an owner and a recommended default.
- `Suggested Skills` — tools/skills the next agent should reach for.
- `Do Not Touch` — explicit scope fence (non-goals and surfaces that are off-limits).
- `Promotion Candidates` — items the orchestrator may promote to `Info/`/ADR.

### Header metadata (staleness)

The brief opens with a metadata block so a stale brief is easy to spot:

```text
Last updated:
Current phase:
Current slice:
Based on git commit:        # short SHA the brief reflects
Working tree checked at:    # timestamp of the last tree check
```

### Delivery to workers (by reference)

The orchestrator passes the brief **by reference**, never by pasting the whole file: the coordination packet carries `Context brief path:` and `Read sections:`. The worker reads only the named sections on demand, keeping its prompt bounded.

- **Temp-access fallback:** if a worker cannot read the brief path, it reports that immediately and does not guess. The orchestrator then re-sends only the named sections inline. The file remains the single source of truth; inline delivery is a transport fallback, not a second copy of record.
- **Working tree is truth:** the brief accelerates coordination but never overrides the repository. Workers corroborate brief claims against the working tree before editing (mirroring the graphify freshness rule).

### Promotion to durable artifacts

The brief is the volatile layer; it never replaces `Info/` notes or ADRs. The orchestrator promotes a `Promotion Candidate` to a phase note (`Info/`) or an ADR when the item affects any of: **future phases, user-facing behavior, architecture, public contracts, dependencies, data/schema, security, validation gaps, or follow-up work**. Items that meet none of these stay in the ephemeral brief and are allowed to die with the session.

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
- Graphify graph available and verified fresh: yes/no/absent. If yes, @explore queries graphify-out/ first; if stale, note it and fall back.
- External docs/dependency investigation needed: yes/no. If yes, use @scout.

Affected files:

Implementation steps:
1. [step] -> verify: [check]
2. [step] -> verify: [check]
3. [step] -> verify: [check]

Slice plan (ordered, one concern each, delivered one slice at a time):
1. [slice] -> files: [..] -> verify: [check] -> status: pending
2. [slice] -> files: [..] -> verify: [check] -> status: pending
3. [slice] -> files: [..] -> verify: [check] -> status: pending

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

### Single-slice implementation (default)

Deliver one slice at a time. Each slice prompt must name the single concern, give that slice's own verification, and invoke the Karpathy-Inspired Coding Rules. Do not paste the whole plan into the prompt.

```text
@fullstack-worker Implement ONE slice of the approved plan.

Slice [N] of [M]: [the single concern for this slice]

Apply the Karpathy-Inspired Coding Rules to this slice:
- Think before coding: surface assumptions and the smallest safe path.
- Simplicity first: the minimum code required, no speculative abstractions.
- Surgical changes: touch only what this slice requires; do not refactor adjacent code.
- Goal-driven execution: meet this slice's verification before reporting done.

Coordination packet:
- Phase / phase artifact path:
- Resolved decisions:
- Docs/context to respect:
- Context brief path:
- Read sections: Current Slice, Resolved Decisions, Do Not Touch, Relevant References

Constraints:
- Implement only this slice. Do not start later slices.
- Do not broaden scope or change public APIs, schemas, routes, or env contracts unless this slice requires it.
- Match existing style and project conventions.
- Read only the named brief sections. If you cannot read the brief path, report that immediately instead of guessing; the orchestrator will resend the sections inline. Treat the working tree as the source of truth and corroborate brief claims against it before editing.

Verify (this slice):
[the slice's own check]
- After verification passes, if `graphify-out/` exists at the repo root, run `graphify update .` to refresh the graph and `GRAPH_REPORT.md` (no LLM cost). Skip silently if absent.

Report:
- Changed files, commands run, verification result, whether `graphify update .` ran, blockers, and anything to capture in the phase artifact.
```

### Parallel feature work (independent slices only)

Use this only when slices belong to provably independent, non-overlapping feature scopes. Create one prompt per `@fullstack-worker`, each naming its exact feature scope, boundaries where known, constraints, and verification. Never give two workers overlapping ownership unless explicitly coordinating a handoff. Within its scope, each worker still follows the single-slice rules above: work surgically, apply the Karpathy-Inspired Coding Rules, and verify before reporting.

### Repair / test / build correction

```text
@repair-worker Fix this focused issue using the smallest safe change.

Evidence:
[failing output / repro / diff / test name / lint/type/build error]

Expected result:
[desired behavior or passing validation]

Coordination packet:
- Context brief path:
- Read sections: Current Slice, Resolved Decisions, Open Questions

Constraints:
- Start from the evidence.
- Identify root cause where feasible.
- Read only the named brief sections. If you cannot read the brief path, report that immediately; the orchestrator will resend the sections inline. The working tree is the source of truth.
- Do not broaden scope.
- Do not delete tests, weaken assertions, disable checks, or ignore errors unless explicitly approved.
- Match existing style and project conventions.
- Run the relevant validation or explain why it cannot be run.
- After validation passes, if `graphify-out/` exists at the repo root, run `graphify update .` to refresh the graph and `GRAPH_REPORT.md` (no LLM cost). Skip silently if absent.
- Report evidence, root cause, changed files, commands run, validation results, whether `graphify update .` ran, and unresolved risks.
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
- Context brief path:
- Read sections: Promotion Candidates, Resolved Decisions, Relevant References

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

Coordination packet:
- Context brief path:
- Read sections: Resolved Decisions, Do Not Touch, Current Slice

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
