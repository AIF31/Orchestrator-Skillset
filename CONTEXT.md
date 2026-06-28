# CONTEXT — domain glossary

Canonical language for the coordinator workflow. This file is a **glossary only**: it
fixes the meaning of overloaded terms so agent prompts and docs use them consistently.
It is not a spec, a changelog, or an implementation log. Implementation decisions live in
`docs/adr/`; per-phase notes live in `Info/`.

## graphify terms

The word "graphify" covers two distinct operations that earlier prompts conflated. Keep
them separate — the read path answers questions, the refresh path rebuilds the artifact.

- **Graph read path** — `graphify query "<question>"`, `graphify path "A" "B"`,
  `graphify explain "<node>"` (CLI, `--graph graphify-out/graph.json`). Answers "what
  connects to what", callers, and impact radius from `graph.json`. **Read-only: it never
  mutates the graph.** This is the path to reach for before grepping the codebase for
  relationship/impact questions.

- **Graph refresh path** (a.k.a. graph write path) — `graphify update .`. Re-extracts code
  files via AST and rebuilds `graph.json` + `GRAPH_REPORT.md`. **No LLM cost; it is not a
  query** and answers no question by itself. Run after a verified slice to keep the graph
  current. See `docs/adr/0002-graphify-as-queryable-graph.md`.

- **graph-first** — orienting and answering impact/relationship questions via the **read
  path** (and `GRAPH_REPORT.md`) before falling back to grep/file scanning. It does **not**
  mean running `graphify update`. "graph-first" is about reading, not refreshing.

- **fresh graph / stale graph** — a graph is *fresh* (trustworthy) only when it passes the
  freshness gate (graphify post-commit hook installed, or `graph.json` committed at/after
  the latest source, or refreshed in-session by a per-slice `graphify update .`). Otherwise
  it is *stale* and the read path is not trusted — fall back to files and flag it. The gate
  is defined in `skills/coordinator-workflow/SKILL.md` (Graphify Graph-First Exploration).

- **graphify-out/** — the output directory. `graph.json` and `GRAPH_REPORT.md` are always
  present after a build; `wiki/` exists **only** when built with `--wiki`. Check before
  reading optional outputs.

## related coordination terms

- **Plan Handoff Packet** — the durable, one-way strategic handoff from `plan-architect` to
  `plan-orchestrator`. See `docs/adr/0001-session-context-brief.md`.
- **Session Context Brief** — the ephemeral, within-session context feed the orchestrator
  owns and passes to workers by reference. Distinct from the Plan Handoff Packet; the word
  "handoff" never refers to it. See `docs/adr/0001-session-context-brief.md`.
