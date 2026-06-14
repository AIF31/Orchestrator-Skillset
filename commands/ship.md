---
description: Run the model-agnostic plan-first engineering workflow through the orchestrator
agent: plan-orchestrator
---

Use the coordinator-workflow skill.

Handle this engineering task end-to-end. First inspect only the context needed. Use @explore for repo uncertainty (querying a verified, up-to-date `graphify-out/` knowledge graph first when present) and @scout for dependency or docs uncertainty. Then propose a bounded plan and wait for approval before edits unless implementation was already explicitly authorized. Do not hand the worker the whole plan at once: decompose it into small, independently verifiable slices (one concern each) and delegate one slice per @fullstack-worker invocation, each applying the Karpathy-Inspired Coding Rules, verifying each slice against its own check before releasing the next. Use parallel workers only for provably independent feature scopes. Review the diff against the plan after each slice and at the end, and confirm relevant docs and phase artifacts were updated.

Task: $ARGUMENTS
