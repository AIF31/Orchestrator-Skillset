# Fusion Deep-Planning Agent (`plan-architect`)

Rationale and operating notes for the optional Fusion-backed planning agent.
This feature is **optional**, **cost-sensitive**, and depends on a **beta**
OpenRouter capability. The default model-agnostic workflow does not require it.

## What it is

`plan-architect` is a single, read-only, primary planning agent backed by
[OpenRouter Fusion](https://openrouter.ai/docs/guides/routing/routers/fusion-router).
It is used **only at the kickoff of a large or high-stakes project** to create,
discuss, and redline the master Phase/Implementation Plan. It produces a
detailed-but-general strategic plan (architecture, phases, module/seam map,
risks, verification strategy) and hands off to `plan-orchestrator`, which
decomposes the plan into slices and runs the normal slice -> worker -> review
loop.

The boundary is deliberate:

- `plan-architect` = the **strategic** plan (what and why). Stops at phase
  granularity.
- `plan-orchestrator` = the **tactical** execution (how). Owns slicing and
  per-slice worker assignment.

The plan artifact is the handoff interface, so execution never depends on Fusion
once the plan exists.

## Why scope it this narrowly

Fusion is a multi-model deliberation pipeline: a panel of up to 8 models answers
in parallel, a judge synthesizes their responses (consensus, contradictions,
partial coverage, unique insights, blind spots), and the outer model writes the
final answer. That is valuable exactly where "being wrong is expensive" — a
big-project kickoff plan — and wasteful for routine implementation. Attaching it
to implementation/repair workers would add cost and latency and blur the clean
planner/worker separation, so it is confined to one read-only planning role.

## How it is wired

- Agent definition: `examples/opencode.fusion-planning-agent.jsonc` (a merge
  template; the main example config stays model-agnostic).
- Prompt: `examples/prompts/plan-architect.md`.
- Model field: `openrouter/fusion` (the only provider-specific part). The agent
  name stays role-based per the project's naming policy.
- Permissions: read-only on product code. `edit` is allowed but the prompt
  restricts it to planning artifacts only (the plan ADR/phase note and
  `CONTEXT.md`) — the same prompt-enforced posture `docs-maintainer` already
  uses. It may delegate to `@explore` and `@scout` only; not to implementation,
  repair, or docs workers.

## Prompt lineage

The prompt composes three skills, adapted to planning:

- Karpathy-Inspired Coding Rules — think before planning, simplicity first
  (set explicitly against Fusion's tendency to broaden — "deliberate widely,
  then converge"), surgical scope, goal-driven (every phase has a verification).
- `improve-codebase-architecture` — evaluate designs by module depth, the
  deletion test, seams/adapters, and locality; the module/seam map is what lets
  the orchestrator assign non-overlapping worker scopes.
- `grill-with-docs` — one question at a time with a recommended answer; explore
  instead of asking; challenge terminology/vagueness/assumptions/code-drift;
  capture terms in `CONTEXT.md`, hard-to-reverse decisions in ADRs.

## Operating limits (read before relying on it)

These follow from using the `openrouter/fusion` model alias inside OpenCode:

- **Cost: ~4-5x a single completion** with the default 3-model panel, scaling
  linearly with panel size, and on premium panel models (Quality preset:
  Claude Opus / GPT-latest / Gemini Pro). Pay it once, at kickoff. Trivial
  follow-up turns ("rename phase 2") generally do not trigger the panel, so cost
  self-regulates during redlining.
- **Opportunistic invocation.** The outer model decides whether to invoke the
  Fusion panel; on prompts it judges "simple" it may answer directly. Kickoff
  design prompts are non-simple, so this is low-risk here — but confirm the
  panel actually fired via the OpenRouter Activity log (it shows which models
  executed).
- **Prose output, not structured JSON.** Via the alias, the judge's structured
  analysis is consumed internally and you receive a synthesized prose answer.
  That is the right shape for a human-readable plan/redline; it is the wrong
  shape for machine-consumed review, which is why Fusion is not wired into
  `code-reviewer`.
- **Judge/outer model defaults to the Quality preset**, not your
  `plan-orchestrator` model or reasoning options. Acceptable (Opus-class
  synthesis) for planning; just know your `reasoningEffort` config does not
  apply to this agent.
- **Beta.** OpenRouter server tools / Fusion are beta; API and behavior may
  change. The feature is isolated and optional so the default workflow is never
  affected.

## Prerequisite check

Before using the agent, confirm your OpenRouter provider is configured with a
key and that `openrouter/fusion` resolves in your OpenCode install. If it does
not, the agent is blocked and nothing else about the feature matters.

## Suggested one-time validation

The marginal value of Fusion over a single strong reasoning model on a planning
task is plausible but unproven. On your first real kickoff, run the same prompt
once via `openrouter/fusion` and once via a strong single model, and compare the
resulting plans before committing to the agent long-term.

## References

- Fusion router: https://openrouter.ai/docs/guides/routing/routers/fusion-router
- Fusion plugin: https://openrouter.ai/docs/guides/features/plugins/fusion
- Fusion server tool: https://openrouter.ai/docs/guides/features/server-tools/fusion
