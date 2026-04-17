# plan/ — Planning documents

Two documents, read in order:

1. **[brief.md](brief.md)** — the upstream meta-prompt that set up this project's planning mode: philosophy, constraints, output format, non-goals. **Don't edit** — it's the immutable requirements statement.

2. **[project-partition.md](project-partition.md)** — the authoritative backlog. Full architecture, 8-section `robocup.pl` layout, tasks T0.0 → T7.4 with acceptance criteria, dependency graph, verification commands, risks. **This is where subagents find task bodies**.

## How subagents consume this

Each subagent reads two files before acting:

- `docs/project-context.md` — short single-source-of-truth (decisions, data shapes, predicate contracts).
- `plan/project-partition.md` — the task body for the T-id they were dispatched with.

Subagent role definitions live in [`.claude/agents/`](../.claude/agents/).

## Change discipline

- `project-partition.md` is the canonical backlog. Every structural change to the project plan goes here first.
- `docs/project-context.md` is derived from `project-partition.md`. Update it whenever shared predicate contracts, data shapes, or locked decisions change.
- `brief.md` is read-only.
