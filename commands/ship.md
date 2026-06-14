---
description: Run the model-agnostic plan-first engineering workflow through the orchestrator
agent: plan-orchestrator
---

Use the coordinator-workflow skill.

Handle this engineering task end-to-end. First inspect only the context needed. Use @explore for repo uncertainty (querying a verified, up-to-date `graphify-out/` knowledge graph first when present) and @scout for dependency or docs uncertainty. Then propose a bounded plan and wait for approval before edits unless implementation was already explicitly authorized. Use exactly one implementation worker per change-set unless explicitly coordinating a handoff. Review the final diff against the plan and confirm relevant docs and phase artifacts were updated.

Task: $ARGUMENTS
