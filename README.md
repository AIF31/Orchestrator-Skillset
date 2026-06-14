# Orchestrator-Skillset

<p align="center">
  <a href="https://opencode.ai"><img src="https://img.shields.io/badge/OpenCode-skill-111827?style=for-the-badge" alt="OpenCode skill"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue?style=for-the-badge" alt="MIT license"></a>
  <img src="https://img.shields.io/badge/workflow-model--agnostic-6f42c1?style=for-the-badge" alt="Model agnostic workflow">
</p>

## OpenCode Coordinator Workflow

**OpenCode Coordinator Workflow: a model-agnostic software engineering SOP to plan first, delegate narrowly, repair from evidence, and review before shipping.**

Orchestrator-Skillset turns ad hoc OpenCode coding sessions into a repeatable planner-worker-review system. It separates investigation, implementation, repair, and review into role-based agents so you can swap models without rewriting your operating procedure.

Use it when you want OpenCode to behave like a senior engineering lead: inspect only what matters, define success criteria before edits, delegate implementation to as many feature-scoped workers as necessary, capture decisions in durable phase artifacts, and keep destructive actions behind explicit approval.

## Quickstart

Clone the repository and install the skill globally:

```bash
git clone git@github.com:AIF31/Orchestrator-Skillset.git
cd Orchestrator-Skillset
mkdir -p ~/.config/opencode/skills
cp -R skills/coordinator-workflow ~/.config/opencode/skills/
```

Merge the example agents and permissions into your OpenCode config:

```bash
mkdir -p ~/.config/opencode
cp examples/opencode.model-agnostic-agents.jsonc ~/.config/opencode/opencode.jsonc
```

Install the workflow slash commands (one file per command):

```bash
mkdir -p ~/.config/opencode/commands
cp commands/*.md ~/.config/opencode/commands/
```

Restart OpenCode after installing or changing skills, agents, commands, or config.

## Try It

After installing the commands, use the workflow slash commands. Each is one file in `commands/`, and each routes to the role-based agent that owns that step:

```text
/ship add dark mode support to the settings page
/bug reproduce and fix the checkout validation error
/implement build the approved settings-page plan exactly
/repair fix the failing typecheck
/fix-review apply only the review fixes from the previous message
/review review the active diff for security and correctness issues
/docs update the README and Info/ notes for the new settings workflow
/graphify-explore map the auth flow and its impact radius
```

| Command | Agent | Use for |
|---------|-------|---------|
| `/ship` | `plan-orchestrator` | Full plan-first workflow for a feature or change. |
| `/bug` | `plan-orchestrator` | Bug workflow that gathers evidence then delegates to repair. |
| `/implement` | `fullstack-worker` | Implement an already-approved plan directly. |
| `/repair` | `repair-worker` | Deterministic test/lint/typecheck/build/CI repair or a stuck-worker retry. |
| `/fix-review` | `repair-worker` | Apply only the review fixes from the previous message. |
| `/review` | `code-reviewer` | Optional independent read-only review of the current diff. |
| `/docs` | `docs-maintainer` | Update README, Info/ notes, and related docs. |
| `/graphify-explore` | `explore` | Graph-first repo exploration using a verified `graphify-out/` graph. |

`/graphify-explore` runs graph-first repo exploration: if a verified, up-to-date `graphify-out/` knowledge graph is present it queries that first, otherwise it explores the files normally. (Named `/graphify-explore` to avoid colliding with graphify's own `/graphify` command.)

Or invoke the agents directly from OpenCode:

```text
@plan-orchestrator plan the smallest safe fix for this failing test
@fullstack-worker implement the approved plan exactly
@repair-worker fix this deterministic build failure from the attached output
@docs-maintainer update README and Info/ notes for the approved change
@code-reviewer review the current diff against the approved plan
```

## Why This Exists

Most agentic coding failures come from the same few problems:

- The agent starts editing before it understands the repo.
- Multiple workers touch overlapping change-sets and create conflicting diffs.
- A bug fix turns into an unplanned refactor.
- Validation fails and the next loop guesses instead of using evidence.
- Review happens as a summary, not a diff check against the plan.
- Documentation drifts out of date after changes ship.

This workflow makes those failure modes explicit. The orchestrator plans and reviews. Implementation workers edit only after a bounded plan exists and each worker has a precise, non-overlapping feature scope. The repair worker starts from logs, test names, diffs, or repro steps. The docs maintainer keeps README.md and Info/ notes aligned with what actually shipped. The reviewer stays read-only and is reserved for changes where independent review is worth the cost.

## What You Get

| Component | Path | Purpose |
|-----------|------|---------|
| Skill | `skills/coordinator-workflow/SKILL.md` | The installable OpenCode workflow SOP. |
| Example config | `examples/opencode.model-agnostic-agents.jsonc` | Agent definitions, permissions, and reasoning options. |
| Workflow commands | `commands/*.md` | One slash command per file: ship, bug, implement, repair, fix-review, review, docs, graphify-explore. |
| License | `LICENSE` | MIT license for public reuse. |

## Agent Roles

| Agent | Mode | Responsibility |
|-------|------|----------------|
| `plan-orchestrator` | primary | Plans, routes, controls scope, and reviews the final diff. |
| `explore` | built-in subagent | Reads the repository to find files, patterns, tests, and impact radius; queries a verified `graphify-out/` knowledge graph first when present. |
| `scout` | subagent | Researches external docs, SDK behavior, dependencies, frameworks, and upstream source. |
| `fullstack-worker` | subagent | Implements approved frontend, backend, full-stack, docs, config, and refactor plans. |
| `repair-worker` | subagent | Fixes bugs, tests, lint, typecheck, build, CI, and correction-loop failures from evidence. |
| `docs-maintainer` | subagent | Keeps README.md, Info/ research notes, architecture docs, usage docs, and examples accurate after relevant changes. |
| `code-reviewer` | subagent | Performs optional read-only independent review for high-risk or user-requested checks. |

## How It Works

1. The orchestrator clarifies the smallest useful outcome.
2. It uses `@explore` for repo uncertainty and `@scout` for version-sensitive external research. When the project carries a verified, up-to-date `graphify-out/` knowledge graph, `@explore` queries the graph first and falls back to file scanning only when it is missing or stale.
3. It writes a bounded plan with assumptions, affected files, implementation steps, verification, risks, and worker choice.
4. It delegates to one or more implementation workers when the work decomposes into precise, non-overlapping feature scopes.
5. For named phases, it creates or delegates a Markdown phase artifact: an ADR for hard-to-reverse decisions, a phase note for implementation summaries, or an update to an existing canonical phase/changelog doc.
6. It sends workers a coordination packet with the phase, artifact path, resolved decisions, open questions, docs/context to respect, and docs to update or report back.
7. `@fullstack-worker` handles normal approved implementation work, with one clear feature scope per worker, and can run standard verification commands such as lint, typecheck, test, build, check, CSS audit, coverage, and perf checks.
8. `@repair-worker` handles bugs, failed validation, focused corrections, and root-cause loops.
9. The orchestrator reviews the current diff against the original plan and confirms the phase artifact was updated when relevant.
10. `@docs-maintainer` updates README.md, phase artifacts, Info/ notes, and related docs when the change or research result should be captured durably.
11. `@code-reviewer` is used only when independent review is justified by risk or requested by the user.

## Graphify Graph-First Exploration (Optional)

[`graphify`](https://github.com/safishamsi/graphify) is a separate, optional tool that turns a codebase into a queryable knowledge graph (`graphify-out/`). This workflow integrates with it but does not require it: when a verified, up-to-date graph is present, `@explore` uses it as the first lookup surface — `graphify query`, `graphify path`, and `graphify explain` answer "what connects to what" and impact-radius questions faster than grepping, and `graphify-out/GRAPH_REPORT.md` gives a quick orientation pass.

### Why use it with this skill

- **Faster, cheaper exploration.** Graph lookups replace broad grep/file sweeps, so `@explore` spends fewer tokens locating affected files, call paths, and impact radius before a plan is written.
- **Better impact analysis.** `graphify path "A" "B"` and `graphify explain "X"` surface dependency and call relationships that are easy to miss with text search, which tightens the orchestrator's "affected files" and risk sections.
- **No API cost for code.** Graphify extracts code locally via tree-sitter (AST), so building and refreshing the graph for a code-only repo runs fully offline with no API key.
- **Stays optional and safe.** When `graphify-out/` is absent or stale, exploration falls back to normal file scanning — the working tree always remains the source of truth.

### Install graphify

See the [official graphify repository](https://github.com/safishamsi/graphify) for full docs. The PyPI package is `graphifyy` (double-y) and requires Python 3.10+:

```bash
uv tool install graphifyy   # recommended; or: pipx install graphifyy / pip install graphifyy
graphify .                  # build the graph -> writes graphify-out/
graphify hook install       # optional: rebuild graph.json from the AST after every commit (no API cost)
```

Code-only extraction needs no API key; semantic processing of docs, PDFs, or images requires an LLM backend (see the graphify docs).

### How freshness is verified

The graph is trusted only when verified fresh: either a `graphify hook install` post-commit auto-rebuild hook is installed, or the last commit touching `graphify-out/graph.json` is at or newer than the last commit touching source. If the graph is stale, `@explore` falls back to file-based exploration and flags it (recommend `/graphify . --update`). When `graphify-out/` is absent, exploration proceeds exactly as before.

## Coordination And Phase Artifacts

The workflow includes a lightweight adaptation of `grill-with-docs` for plan-orchestrator coordination. Before major phases or ambiguous plans, the orchestrator checks existing domain language and decisions in `CONTEXT.md`, `CONTEXT-MAP.md`, ADRs, README files, `Info/`, changelogs, and implementation plans. It challenges conflicting terms, cross-checks claims against code/docs, asks one precise question only when exploration cannot answer it, and records resolved decisions in the relevant artifact.

Phase artifacts prevent important context from existing only in worker messages or git diff. Use:

- ADRs for hard-to-reverse architecture, security, runtime, data, dependency, schema, or platform decisions.
- Phase notes for implementation scope, validation results, handoffs, and follow-ups.
- Existing canonical docs when the repo already has a phase log, changelog, implementation plan, or milestone file.

The orchestrator remains accountable for ensuring each completed phase has an artifact or explicit canonical-doc update, even when the artifact work is delegated to `@docs-maintainer`.

## Commit Behavior

The orchestrator may stage and commit when the user explicitly asks it to commit, or after it asks and receives approval. Before committing, it must inspect `git status`, `git diff`, and recent `git log`, confirm the correct repository boundary, stage only intended files, and use a concise message matching the repository style.

Workers still do not commit by default. `@fullstack-worker`, `@repair-worker`, and `@docs-maintainer` can stage only when their permission policy asks/approves, and their default posture denies commits. Pushes remain gated.

## Model-Agnostic By Design

Agent names describe roles, not providers.

To test a different model, edit only the `model` field in `examples/opencode.model-agnostic-agents.jsonc` or your installed `~/.config/opencode/opencode.jsonc`.

Recommended policy:

- Put `plan-orchestrator` on your strongest planning model.
- Put `code-reviewer` on a strong review model with medium reasoning effort.
- Put `scout` on a low-effort model that can browse or fetch docs efficiently.
- Put `fullstack-worker`, `repair-worker`, and `docs-maintainer` on models that match your cost, speed, context, and reliability needs.

The included example uses role-based defaults and reasoning options:

| Agent | Example reasoning effort |
|-------|--------------------------|
| `plan-orchestrator` | `high` |
| `scout` | `low` |
| `code-reviewer` | `medium` |

## Install Options

### Global Install

Use this when you want the workflow available in every project:

```bash
mkdir -p ~/.config/opencode/skills ~/.config/opencode/commands
cp -R skills/coordinator-workflow ~/.config/opencode/skills/
cp commands/*.md ~/.config/opencode/commands/
```

Then merge or copy the example config:

```bash
cp examples/opencode.model-agnostic-agents.jsonc ~/.config/opencode/opencode.jsonc
```

### Project Install

Use this when a single repository should carry the workflow:

```bash
mkdir -p .opencode/skills .opencode/commands
cp -R skills/coordinator-workflow .opencode/skills/
cp commands/*.md .opencode/commands/
cp examples/opencode.model-agnostic-agents.jsonc .opencode/opencode.jsonc
```

### Symlink For Development

Use this while editing the skill locally:

```bash
mkdir -p ~/.config/opencode/skills
ln -s "$(pwd)/skills/coordinator-workflow" ~/.config/opencode/skills/coordinator-workflow
```

## Configuration

The example config is intentionally public-safe:

- No API keys.
- No local network addresses.
- No private MCP servers.
- No user-specific paths.

Before publishing or sharing your own config, review provider blocks, MCP servers, environment variables, and custom paths.

Important OpenCode behavior:

- `opencode.jsonc` is strict-schema validated.
- Agent names referenced by commands must exist in `agent`.
- Skills are loaded from folders that contain `SKILL.md`.
- Config, skills, agents, and commands are loaded at startup, so restart OpenCode after edits.

## Safety Defaults

The example config keeps high-impact operations gated.

These require explicit approval or are denied by default:

| Operation | Default posture |
|-----------|-----------------|
| `git add *` | ask |
| `git commit *` | ask for orchestrator; deny for workers by default |
| `git push *` | ask or deny for workers |
| `git checkout *` | ask |
| `git switch *` | ask |
| `git restore *` | ask |
| `rm *` | ask |
| `sudo *` | ask or deny for workers |
| `git reset *` | deny |
| `git clean *` | deny |

Review these permissions before installing in a different organization or security environment.

The example config allows `@fullstack-worker` to run standard verification commands without extra approval: `npm run lint`, `npm run typecheck`, `npm run test`, `npm run build`, `npm run check`, `npm run css:audit`, `npm run css:audit:strict`, `npm run test:coverage`, and `npm run test:perf`. Package installation and arbitrary `npm *` commands still ask.

## Repository Structure

```text
.
├── README.md
├── LICENSE
├── commands/
│   ├── bug.md
│   ├── docs.md
│   ├── fix-review.md
│   ├── graphify-explore.md
│   ├── implement.md
│   ├── repair.md
│   ├── review.md
│   └── ship.md
├── examples/
│   └── opencode.model-agnostic-agents.jsonc
└── skills/
    └── coordinator-workflow/
        └── SKILL.md
```

## Publishing Checklist

Before making a public release:

- Validate `examples/opencode.model-agnostic-agents.jsonc` against the OpenCode schema.
- Confirm all model IDs are available to your expected users.
- Confirm the example contains no private provider, MCP, path, token, or hostname values.
- Tag a release after verifying install instructions on a clean OpenCode profile.

## Contributing

Contributions are welcome.

Good contributions usually improve one of these areas:

- Clearer orchestration rules.
- Safer permissions.
- Better command wrappers.
- More portable example config.
- Better docs for installing and adapting the workflow.

Please keep the project model-agnostic. Avoid naming agents after providers or model families unless the role itself is provider-specific.

## License

MIT. See [`LICENSE`](LICENSE).
