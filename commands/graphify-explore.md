---
description: Explore the repo graph-first using a verified graphify-out/ knowledge graph
agent: explore
---

Use the coordinator-workflow skill.

Run read-only repository exploration for the current task, graph-first.

Steps:
- Detect graphify-out/graph.json at the project root. If absent, explore the files normally.
- Verify freshness before trusting the graph: check whether a graphify post-commit hook is installed (`graphify hook install`, visible in `.git/hooks/post-commit`), or compare the last commit touching graphify-out/graph.json against the last commit touching source (`git log -1 --format=%cI -- graphify-out/graph.json` vs the source dirs). Treat the graph as stale if source has newer commits, if graph.json has merge-conflict markers, or if large uncommitted source changes are not yet reflected.
- If fresh, the graph's read path is the FIRST move for any "what connects / what uses / who calls / impact radius / path A→B" question: run `graphify query "..."`, `graphify path "A" "B"`, or `graphify explain "X"` (`--graph graphify-out/graph.json`) before any grep or broad file scan, and read graphify-out/GRAPH_REPORT.md for orientation. **Never grep graphify-out/ — query the graph instead of grepping its output files.** Read order: graph.json and GRAPH_REPORT.md are always present; wiki/ exists only if built with `--wiki`, so check before reading it. Plain string/single-file lookups stay free-form. Always corroborate graph claims against the actual files.
- If stale or absent, explore the files and flag the staleness (recommend `/graphify . --update` or `/graphify .`). Do not rebuild the graph during read-only exploration.

Report relevant files, patterns, call paths, impact radius, and whether the graphify graph was used or skipped (with the reason).
