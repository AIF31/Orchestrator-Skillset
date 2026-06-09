# OpenCode Coordinator Workflow

<p align="center">
  <a href="https://opencode.ai"><img src="https://img.shields.io/badge/OpenCode-skill-111827?style=for-the-badge" alt="OpenCode skill"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue?style=for-the-badge" alt="MIT license"></a>
  <img src="https://img.shields.io/badge/workflow-model--agnostic-6f42c1?style=for-the-badge" alt="Model agnostic workflow">
</p>

**A model-agnostic software engineering SOP for OpenCode: plan first, delegate narrowly, repair from evidence, and review before shipping.**

OpenCode Coordinator Workflow turns ad hoc coding sessions into a repeatable planner-worker-review system. It separates investigation, implementation, repair, and review into role-based agents so you can swap models without rewriting your operating procedure.

Use it when you want OpenCode to behave like a senior engineering lead: inspect only what matters, define success criteria before edits, use one implementation worker per change-set, and keep destructive actions behind explicit approval.

## Quickstart

Clone the repository and install the skill globally:

```bash
git clone git@github.com:AIF31/Orchestrator-Skillset.git
cd Orchestrator-Skillset
mkdir -p ~/.config/opencode/skills
cp -R skills/coordinator-workflow ~/.config/opencode/skills/
```

Merge the example agents and commands into your OpenCode config:

```bash
mkdir -p ~/.config/opencode
cp examples/opencode.model-agnostic-agents.jsonc ~/.config/opencode/opencode.jsonc
```

Optional command wrappers:

```bash
mkdir -p ~/.config/opencode/commands
cp commands/*.md ~/.config/opencode/commands/
```

Restart OpenCode after installing or changing skills, agents, commands, or config.

## Try It

After installing the example config, use the workflow commands:

```text
/ship add dark mode support to the settings page
/bug reproduce and fix the checkout validation error
/repair fix the failing typecheck
/review review the active diff for security and correctness issues
```

Or invoke the agents directly from OpenCode:

```text
@plan-orchestrator plan the smallest safe fix for this failing test
@fullstack-worker implement the approved plan exactly
@repair-worker fix this deterministic build failure from the attached output
@code-reviewer review the current diff against the approved plan
```

## Why This Exists

Most agentic coding failures come from the same few problems:

- The agent starts editing before it understands the repo.
- Multiple workers touch the same change-set and create conflicting diffs.
- A bug fix turns into an unplanned refactor.
- Validation fails and the next loop guesses instead of using evidence.
- Review happens as a summary, not a diff check against the plan.

This workflow makes those failure modes explicit. The orchestrator plans and reviews. The implementation worker edits only after a bounded plan exists. The repair worker starts from logs, test names, diffs, or repro steps. The reviewer stays read-only and is reserved for changes where independent review is worth the cost.

## What You Get

| Component | Path | Purpose |
|-----------|------|---------|
| Skill | `skills/coordinator-workflow/SKILL.md` | The installable OpenCode workflow SOP. |
| Example config | `examples/opencode.model-agnostic-agents.jsonc` | Agent definitions, permissions, reasoning options, and workflow commands. |
| Command wrappers | `commands/*.md` | Optional shortcuts for implementation, repair, and review flows. |
| License | `LICENSE` | MIT license for public reuse. |

## Agent Roles

| Agent | Mode | Responsibility |
|-------|------|----------------|
| `plan-orchestrator` | primary | Plans, routes, controls scope, and reviews the final diff. |
| `explore` | built-in subagent | Reads the repository to find files, patterns, tests, and impact radius. |
| `scout` | subagent | Researches external docs, SDK behavior, dependencies, frameworks, and upstream source. |
| `fullstack-worker` | subagent | Implements approved frontend, backend, full-stack, docs, config, and refactor plans. |
| `repair-worker` | subagent | Fixes bugs, tests, lint, typecheck, build, CI, and correction-loop failures from evidence. |
| `code-reviewer` | subagent | Performs optional read-only independent review for high-risk or user-requested checks. |

## How It Works

1. The orchestrator clarifies the smallest useful outcome.
2. It uses `@explore` for repo uncertainty and `@scout` for version-sensitive external research.
3. It writes a bounded plan with assumptions, affected files, implementation steps, verification, risks, and worker choice.
4. It delegates to exactly one implementation worker for the change-set.
5. `@fullstack-worker` handles normal approved implementation work.
6. `@repair-worker` handles bugs, failed validation, focused corrections, and root-cause loops.
7. The orchestrator reviews the current diff against the original plan.
8. `@code-reviewer` is used only when independent review is justified by risk or requested by the user.

## Model-Agnostic By Design

Agent names describe roles, not providers.

To test a different model, edit only the `model` field in `examples/opencode.model-agnostic-agents.jsonc` or your installed `~/.config/opencode/opencode.jsonc`.

Recommended policy:

- Put `plan-orchestrator` on your strongest planning model.
- Put `code-reviewer` on a strong review model with medium reasoning effort.
- Put `scout` on a low-effort model that can browse or fetch docs efficiently.
- Put `fullstack-worker` and `repair-worker` on models that match your cost, speed, context, and reliability needs.

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
| `git commit *` | ask or deny for workers |
| `git push *` | ask or deny for workers |
| `git checkout *` | ask |
| `git switch *` | ask |
| `git restore *` | ask |
| `rm *` | ask |
| `sudo *` | ask or deny for workers |
| `git reset *` | deny |
| `git clean *` | deny |

Review these permissions before installing in a different organization or security environment.

## Repository Structure

```text
.
├── README.md
├── LICENSE
├── commands/
│   ├── fix-review.md
│   ├── implement-secondary.md
│   └── implement.md
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
