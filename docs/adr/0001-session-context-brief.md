# ADR 0001 — Session Context Brief for orchestrator↔worker coordination

- **Status:** Accepted
- **Date:** 2026-06-16
- **Deciders:** Alan (maintainer)
- **Context skill:** `coordinator-workflow` (`compatibility: opencode`)
- **Relates to:** Plan Handoff Packet (plan-architect → plan-orchestrator), Coordinator Grill-With-Docs Protocol

## Context

We wanted to feed a handoff-style context document (document shape borrowed from
mattpocock's `productivity/handoff` skill) into the coordinator workflow so the
orchestrator and its sub-agents share more context during a task. Several forces
constrained the design:

1. **Borrowed shape vs. local purpose.** mattpocock's `/handoff` compacts a
   *conversation* to the OS temp dir so a *fresh, context-less agent in a new
   session* can resume. Our need is different: an in-flight, **within-session**
   context feed from the live orchestrator down to bounded workers.
2. **Terminology collision.** The skill already used "Handoff Packet" for the
   plan-architect → orchestrator strategic handoff (durable, up→down, once).
   Reusing "handoff" for a second, different mechanism would make every agent
   prompt ambiguous.
3. **Bounded-worker principle.** Workers are deliberately fresh, single-slice,
   small-context invocations. Any shared context must not bloat their prompts.
4. **Durable-artifact principle.** The workflow treats `Info/` and `docs/adr/`
   as the durable coordination record that survives context loss; git diff is
   explicitly not the only source of truth.

A second question was raised: should sub-agents return their own handoff back up?
Grilling it showed the return path has **no context boundary** (the orchestrator
is live and receives the worker report as the tool result), and workers already
return structured reports. A symmetric upward handoff would be a renamed
duplicate, so it was rejected.

## Decision

Introduce a single **Session Context Brief**:

- **Purpose:** within-session shared context, not cross-session resume.
- **Owner:** `@plan-orchestrator` — seeds at kickoff, refreshes on resolved
  decisions and phase transitions. No worker writes or owns it.
- **Storage:** OS temp dir (e.g. `${TMPDIR:-/tmp}/coordinator-brief-<task-slug>.md`),
  ephemeral. Lifetime == the task; it is expected to disappear at session end.
  It is a *feed*, not a *record*.
- **Shape:** borrowed from a handoff document — summary, references-not-
  duplication, redacted secrets, suggested skills.
- **Canonical sections (stable headings, so `Read sections:` is meaningful):**
  `Current Slice`, `Resolved Decisions`, `Relevant References`, `Open Questions`,
  `Suggested Skills`, `Do Not Touch` (the scope fence — non-goals and off-limits
  surfaces), `Promotion Candidates`.
- **Header metadata (staleness):** `Last updated`, `Current phase`,
  `Current slice`, `Based on git commit`, `Working tree checked at`.
- **Downward delivery (orchestrator → worker):** **by reference** — the
  coordination packet carries `Context brief path:` + `Read sections:`; the
  worker reads only the named sections.
- **Temp-access fallback:** if a worker cannot read the path, it reports that
  immediately and the orchestrator re-sends only the named sections inline. The
  file remains the single source of truth; inline delivery is a transport
  fallback, not a second copy of record.
- **Upward flow (worker → orchestrator):** the worker returns its existing
  inline report; the orchestrator **infers** brief updates. **No new worker
  return contract.** (The packet does add `Context brief path:` / `Read
  sections:` — a change to worker *input/prompt* contract, not output.)
- **Per-role routing:**
  - `fullstack-worker` → `Current Slice`, `Resolved Decisions`, `Do Not Touch`,
    `Relevant References`.
  - `repair-worker` → `Current Slice`, `Resolved Decisions`, `Open Questions`.
  - `docs-maintainer` → `Promotion Candidates`, `Resolved Decisions`,
    `Relevant References`.
  - `code-reviewer` → `Resolved Decisions`, `Do Not Touch`, `Current Slice`.
- **Promotion criterion:** promote a `Promotion Candidate` to `Info/`/ADR when it
  affects **future phases, user-facing behavior, architecture, public contracts,
  dependencies, data/schema, security, validation gaps, or follow-up work**.
  Otherwise it stays in the ephemeral brief and dies with the session.
- **Naming:** the new artifact is the **Session Context Brief**; the existing
  plan-architect mechanism is clarified as the **Plan Handoff Packet**. The bare
  word "handoff" no longer denotes two things.

### Guardrails

- **Volatile layer only.** The brief never replaces `Info/`/ADRs; durable items
  are promoted per the criterion above.
- **Working tree is truth.** Workers corroborate brief claims against the working
  tree before editing; the `Based on git commit` / `Working tree checked at`
  header makes a stale brief easy to spot.

## Alternatives considered

- **Literal cross-session `/handoff` to temp + resume.** Rejected: not the stated
  need (in-workflow feed), and OpenCode may have no `/handoff` to invoke — we want
  the document *shape*, not the skill call.
- **Durable brief in `Info/`.** Rejected for the default path: a per-task living
  scratchpad churns git history; durable content already has a home in
  `Info/`/ADR. Temp keeps the workspace clean.
- **Paste brief into worker prompts.** Rejected: fights the bounded-worker
  principle, duplicates content, drifts.
- **Symmetric worker-written return handoff (own temp file).** Rejected: no
  context boundary on the return path; duplicates the existing worker report;
  multiplies lifecycle, redaction surface, and staleness; breaks single-source-
  of-truth.
- **Worker-proposed "brief-delta" block.** Rejected: adds worker-contract surface
  for marginal gain; orchestrator inference is simpler and keeps the orchestrator
  in control.

## Consequences

**Positive**

- One source of truth, one redaction point, one owner.
- Worker prompts stay bounded (reference, not paste).
- Worker / repair / docs / review return contracts and the Completion Report are
  unchanged — the feature is almost entirely orchestrator-side + docs.
- "Handoff" is disambiguated.
- Stable sections enable targeted reads and per-role routing.

**Negative / risks**

- The brief can go stale between refreshes → mitigated by the staleness header +
  working-tree-is-truth rule.
- A worker may be unable to read the temp path → mitigated by the inline-section
  fallback.
- The orchestrator carries inference burden per slice → acceptable; it already
  owns refresh.
- Ephemeral storage means the brief is lost at session end by design → acceptable
  because durable items are promoted via the explicit criterion.

## Implementation

Implemented in `skills/coordinator-workflow/SKILL.md` (new "Session Context
Brief" section, Core Workflow steps 9 and 11, orchestrator responsibilities, and
the four delegation templates) and mirrored in `examples/prompts/*.md`.
