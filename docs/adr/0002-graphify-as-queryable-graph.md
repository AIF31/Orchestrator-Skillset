# ADR 0002 — graphify is a queryable graph, not just a report

- **Status:** Accepted
- **Date:** 2026-06-28
- **Deciders:** Alan (maintainer)
- **Context skill:** `coordinator-workflow` (`compatibility: opencode`)
- **Relates to:** ADR 0001 (Session Context Brief), the graphify integration
  (`https://github.com/safishamsi/graphify`), `CONTEXT.md` glossary

## Context

A real OpenCode session driving this workflow (Phase 5 of the KADO UI Rework) was
analyzed for how it actually used the graphify integration. The finding: the graph was
used **only as a static report plus a write target — never as a queryable graph.**

- `graphify update .` ran 25 times (the refresh/write path — disciplined and correct).
- `graphify-out/GRAPH_REPORT.md` was read for orientation (the static-document path).
- `graphify query` / `graphify path` / `graphify explain` ran **zero** times.
- To answer "is `WorkspaceTopbar` still used anywhere?" the orchestrator **grepped**
  `graphify-out/` for the component name; the `@explore` subagent then re-derived the
  same answer with its own file search. That question — a node's inbound edges — is
  exactly what `graphify explain "WorkspaceTopbar"` answers directly from `graph.json`.

The whole point of carrying a graph (answering "what connects to what" faster and more
completely than text search) was therefore unrealized. Several forces explain why:

1. **Instruction lived in the wrong place.** The SKILL described querying, but the prompts
   that actually load — `examples/prompts/plan-orchestrator.md` and the worker prompts —
   only said "read `GRAPH_REPORT.md` for orientation," or mentioned `query/explain` as a
   weak "you may" aside. The discovery role (`@explore`) had **no role prompt at all**.
2. **No grep redirect.** Nothing told an agent that an impact/relationship question should
   go to the read path before grep, so agents defaulted to the familiar tool.
3. **A read/refresh conflation.** "Use graphify instead of grep" blurred the read path
   (`query/path/explain`) and the refresh path (`update .`); agents internalized the
   refresh half and the static-report half but not the query half.

A standing policy conflict was also surfaced in the session: the skill's "run
`graphify update .` after every slice" contradicted a repo-local AGENTS.md/CLAUDE.md rule
("don't update on ordinary code edits"). The agent flagged it but had no precedence rule.

## Decision

Make the graph's **read path the instructed first move** for relationship/impact questions,
across every agent role, with grep/file-read as an explicit narrow fallback.

- **Enforcement model — instructed-default, not a hard gate.** For "what connects / what
  uses / callers / impact radius / path A→B" questions, agents MUST try
  `graphify query|path|explain` first when a verified-fresh graph exists, and fall back to
  grep/file-read only if the graph is absent, stale, or returns nothing. Plain string/file
  lookups stay free-form. A hard gate (forbidding all grep, requiring a query before any
  scan) was rejected as overhead on trivial lookups that agents would fight.
- **Scope — all four roles.** `explore`, `plan-orchestrator`, `fullstack-worker`, and
  `repair-worker` all carry the rule, because the observed grep happened in the
  *orchestrator*, not only in discovery. Workers keep a "small context" caveat: query a
  node for impact radius instead of grepping or pulling the whole report.
- **Surface — CLI primary.** Standardize on `graphify query|path|explain --graph
  graphify-out/graph.json`. The CLI reads `graph.json` fresh on every call, which fits the
  per-slice `graphify update .` cadence. The MCP server (`python -m graphify.serve`) is kept
  as an optional note for long, stable, read-only sessions — with the caveat that it serves
  a snapshot and must be restarted after a refresh.
- **Discovery role gets a prompt.** Create `examples/prompts/explore.md` (it did not exist).
- **No grep on `graphify-out/`.** Querying the graph replaces grepping its output files.
- **Read order / availability.** `graph.json` and `GRAPH_REPORT.md` are always present after
  a build; `wiki/` only with `--wiki` — check before reading. The orchestrator logs the
  freshness verdict once at session start.
- **Update-cadence precedence — local wins.** A project's installed graphify section
  (AGENTS.md/CLAUDE.md) overrides this skill's default per-slice `graphify update .` cadence;
  the skill default applies only when the project sets no rule.

### Guardrails

- **Working tree is truth.** The graph accelerates discovery; agents still corroborate graph
  claims against the actual files before editing.
- **Freshness gate unchanged.** The read path is trusted only for a graph that passes the
  existing freshness gate (post-commit hook, commit recency, or in-session refresh).

## Alternatives considered

- **Hard gate on all discovery** (forbid grep on `graphify-out/`, require a query before any
  file scan). Rejected: mandatory round-trip on trivial lookups; agents tend to fight gates.
- **Keep the optional "you may query" wording, just louder.** Rejected: that is essentially
  what already produced the grep fallback in the session.
- **`@explore` only.** Rejected: the session's grep was in the orchestrator, so an
  explore-only fix leaves the observed failure path open.
- **MCP server as the primary surface.** Rejected as default: server lifecycle, an opencode
  MCP config step, and a staleness trap under the per-slice refresh cadence. Kept as an
  optional advanced note.

## Consequences

**Positive**

- The graph is finally used for what it is best at — impact radius and "what connects" —
  instead of grep re-deriving it.
- Smaller worker context: a node query beats pulling the whole report or scanning files.
- The read/refresh conflation is named and fixed in `CONTEXT.md`, so future prompt edits stay consistent.
- The standing update-cadence conflict has a deterministic resolution.

**Negative / risks**

- A query against a stale graph could mislead → mitigated by the unchanged freshness gate and
  the working-tree-is-truth rule.
- Slightly more instruction surface across four prompts + SKILL → mitigated by the shared
  glossary and the consistent "instructed-default" phrasing.
- CLI string composition is less ergonomic than MCP tools → accepted for cadence-fit; MCP
  remains available for stable read-only sessions.

## Implementation

Implemented in `skills/coordinator-workflow/SKILL.md` (Graphify Graph-First Exploration,
the `plan-orchestrator`/`fullstack-worker`/`repair-worker` instructions, read-order/freshness
and MCP caveat), the new `examples/prompts/explore.md`, edits to
`examples/prompts/plan-orchestrator.md`, `examples/prompts/fullstack-worker.md`,
`examples/prompts/repair-worker.md`, `commands/graphify-explore.md`, the new root `CONTEXT.md`
glossary, and a `README.md` note.
