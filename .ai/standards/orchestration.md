# Orchestration — Workflow Runner V3

Deterministic routing for `.ai/workflows`. **No LLM decides what to run.**
The runner spends tokens only on selected execution units.

Governed by `.ai/standards/minimalism.md`: minimum agents, minimum context,
maximum deterministic verification.

**Artifacts are earned by complexity, risk, or uncertainty.** Do not create a
spec, ADR, or module doc because a template exists.

## Execution unit

`phase → selected skills` (or selected agents when the phase has no skills).

Phase `agent` / `agents` stay documentation when skills exist. Do not open a
second specialist session for work a skill already owns.

## Adaptive classification (0 tokens, once)

When the caller passes `--request`, `--size`, or `--signals`, classify **once**
before the path router. Heuristic only — no model, no specialist, no second pass.

| Size | Meaning |
|------|---------|
| **S** | Trivial/local (copy, color, label) |
| **M** | Bounded new behavior |
| **L** | Significant feature area |
| **XL** | Architectural / platform change |

Signals are independent of size (size ≠ risk):

`user_behavior_changed` · `database_changed` · `api_changed` · `auth_changed` ·
`architecture_changed` · `setup_changed` · `infrastructure_changed`

Output is a small record (`size` + signals + `reason`). The classifier must not
implement code, write specs/ADRs, invoke specialists, or re-decide mid-workflow.

Without those flags, classification is off: every phase applies (path router
only). `--plan` stays backward-compatible.

### `applies_when` (single line)

OR-clauses split by `/`. A clause is a size list (`L,XL`) or a signal list
(`architecture_changed`). Prefixes `size:`, `any:`, `all:` are optional.

```yaml
applies_when: L,XL
applies_when: XL/architecture_changed
applies_when: L,XL/user_behavior_changed,setup_changed,api_changed
```

Empty / omitted → always. `--full` and `--only` ignore it. A phase omitted by
`applies_when` is **passed** (vacuous) so dependents are not blocked. A human
`--skip` still **blocks** dependents.

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

Regardless of size: security when auth/secrets/authz apply; validation at trust
boundaries; protection against data loss; tests for non-trivial logic; migration
review when migrations exist. Gates and anything passed with `--full` or `--only`.
Do not invent a tokenizer. Do not call a model to choose the next phase.

## Proportional Definition of Done

Strong, not uniform. Map the request, then apply only the earned gates:

| Size / signal | Tests | Review | QA plan | Docs | Spec / stories | ADR |
|---------------|-------|--------|---------|------|----------------|-----|
| S (copy/visual) | Visual check; RSpec only if logic is non-trivial | `ponytail-review` | No | No | No | No |
| S + `auth_changed` | Required | Security review | Yes | No | No | No |
| M | Behavior tests | `ponytail-review` (+ models/migrations if those signals) | Yes | User guide if `user_behavior_changed` / setup / API | Light AC in development if useful | Only if `architecture_changed` |
| L | Critical paths | Full phase reviews | Yes | Matching audience | Yes | If architecture changes |
| XL / `architecture_changed` | Critical paths | Full | Yes | Yes | Yes | Yes + rollout plan |

New Rails apps still bootstrap the test stack first
(`.ai/standards/project-bootstrap.md`).

## CLI

```
rorcc workflow <name> --plan
rorcc workflow <name> --plan --request "Cambiar el texto Login por Entrar"
rorcc workflow <name> --plan --size S --signals auth_changed
rorcc workflow <name> --auto
rorcc workflow <name> --only development,testing
rorcc workflow <name> --skip deployment
rorcc workflow <name> --full
```

## Upgrade path

`# ponytail: heuristic classifier + applies_when, LLM classify only if
measured keyword misses exceed a useful threshold.`
