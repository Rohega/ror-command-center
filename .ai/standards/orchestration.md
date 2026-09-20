# Orchestration — Workflow Runner V3

Deterministic routing for `.ai/workflows`. **No LLM decides what to run.**
The runner spends tokens only on selected execution units.

Governed by `.ai/standards/minimalism.md`: minimum agents, minimum context,
maximum deterministic verification.

## Execution unit

`phase → selected skills` (or selected agents when the phase has no skills).

Phase `agent` / `agents` stay documentation when skills exist. Do not open a
second specialist session for work a skill already owns.

## Router (0 tokens)

A skill is **contextual** when it has YAML `paths:` and its name matches
`review-*`, `*-review`, or `*-audit`.

| Rule | Effect |
|------|--------|
| Skill has no `paths:` | Always selected |
| Skill is not contextual (`create-*`, `document-*`, `qa-plan`, …) | Always selected |
| Contextual skill + none of its `paths:` match the project | Skip (print reason) |
| Contextual skill in a phase that also has a `create-*` skill | Keep — it will review work that phase produces |
| `--full` | Select every declared unit |
| `--only id,id` | Out-of-scope phases are skipped; their absence does **not** block `--only` phases |
| `--skip id` | Phase `skipped`; dependents follow V2 `depends_on` (blocked) |

If every unit in a phase is omitted by the router, the phase is **passed**
(vacuous: nothing applies). A human skip still **blocks** dependents.

Frontend agent-only phases: skip `frontend-react-inertia-developer` when the
tree has no `app/javascript`, `app/frontend`, `app/assets`, `frontend`, or
`app/views`. Other agents always run.

## Autonomy

| Flag | Behavior |
|------|----------|
| (default) | Prompt `[Enter] run · s skip · q quit` per phase; interactive chat |
| `--auto` | No per-phase prompt; one-shot model turn per unit; **gates still require a human** |
| `--plan` | Router + preflight only. Zero LLM calls. No project writes |

`--auto` does not approve gates and does not commit.

## Lean context

Workflow-invoked cloud skills send: specialist `purpose` + `SKILL.md` + named
templates. They do **not** inline every standard the agent YAML references.
Those standards remain binding; the skill already names them.

Standalone `rorcc skill` / `rorcc agent` keep the full assembled prompt.

## Never skip

Gates, security, and anything the user passed with `--full` or `--only`.
Do not invent a tokenizer. Do not call a model to choose the next phase.

## CLI

```
rorcc workflow <name> --plan
rorcc workflow <name> --auto
rorcc workflow <name> --only development,testing
rorcc workflow <name> --skip deployment
rorcc workflow <name> --full
```

## Upgrade path

`# ponytail: deterministic path router, LLM Smart Router only if selection
accuracy is measured and this misses needed reviews.`
