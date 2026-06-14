---
description: Run the bug workflow through the orchestrator, preferring the repair worker
agent: plan-orchestrator
---

Use the coordinator-workflow skill.

Run the bug workflow for this issue. Gather evidence and the likely repro path, produce a bounded plan, and delegate to @repair-worker after approval. Start from evidence, keep the fix to the smallest safe change, and review the diff against the plan before proposing a commit.

Issue: $ARGUMENTS
