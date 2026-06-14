---
description: Explore the repo graph-first using a verified graphify-out/ knowledge graph
agent: explore
---

Use the coordinator-workflow skill.

Run read-only repository exploration for the current task, graph-first.

Steps:
- Detect graphify-out/graph.json at the project root. If absent, explore the files normally.
- Verify freshness before trusting the graph: check whether a graphify post-commit hook is installed (`graphify hook install`, visible in `.git/hooks/post-commit`), or compare the last commit touching graphify-out/graph.json against the last commit touching source (`git log -1 --format=%cI -- graphify-out/graph.json` vs the source dirs). Treat the graph as stale if source has newer commits, if graph.json has merge-conflict markers, or if large uncommitted source changes are not yet reflected.
- If fresh, query the graph instead of grepping: `graphify query "..."`, `graphify path "A" "B"`, `graphify explain "X"`, and read graphify-out/GRAPH_REPORT.md. Always corroborate graph claims against the actual files.
- If stale or absent, explore the files and flag the staleness (recommend `/graphify . --update` or `/graphify .`). Do not rebuild the graph during read-only exploration.

Report relevant files, patterns, call paths, impact radius, and whether the graphify graph was used or skipped (with the reason).
