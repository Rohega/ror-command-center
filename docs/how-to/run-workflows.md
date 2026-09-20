> Language: English | [Español](#versión-en-español)

# Run workflows end-to-end

**Audience:** Anyone using RoR Command Center who wants a guided multi-phase
process (idea → ship, deploy, legacy, incident) without inventing steps.
**Goal:** Pick a workflow, preview it, run it on Cursor / Claude / `rorcc`, and
know what “done” means at each gate.
**Last updated:** 2026-09-20

> Canonical YAML lives in `.ai/workflows/`. This page is the human how-to; agents
> should still **read** the YAML for phase details. Runner rules:
> [`.ai/standards/orchestration.md`](../../.ai/standards/orchestration.md).

---

## Before you start

**Required:**

- [ ] A directory that contains `.ai/` (this cloned repo, or a project created
      with `rorcc init` / `install.sh`)
- [ ] You are **inside** that directory (`pwd` shows the project root)

**Optional (only if you will actually run a model):**

- [ ] Local: Ollama running (`ollama serve`) and a compiled agent (`rorcc build-agent <id>`)
- [ ] Cloud: `OPENAI_API_KEY` or `ANTHROPIC_API_KEY`, then add `--cloud`

`--plan` needs **neither**. Use it first.

---

## Which workflow?

| I want to… | Command name | File |
|------------|--------------|------|
| Build a product capability from idea through deploy | `new-feature` | `.ai/workflows/new-feature.yaml` |
| Plan/execute an AWS release (security + rollback) | `aws-deployment` | `.ai/workflows/aws-deployment.yaml` |
| Inherit a Rails app — document before changing behavior | `legacy-onboarding` | `.ai/workflows/legacy-onboarding.yaml` |
| Production breakage — triage → fix → release → postmortem | `production-incident` | `.ai/workflows/production-incident.yaml` |

A one-line fix does **not** need a workflow. Use one skill + one agent
([use-agents.md](use-agents.md)).

---

## First five minutes (CLI)

Copy these exactly. Expected last lines of `--plan` are shown below.

```bash
cd /path/to/project-with-dot-ai     # or the cloned ror-command-center repo
rorcc workflow new-feature --plan
```

You should see this (verified in this repo on 2026-09-20 — numbers change if you add `app/models` or `config/deploy.rb`):

```
Workflow: new-feature

1. Idea
   id: idea
   selected: create-feature-spec
   agents: product-owner
   dependencies: none
   gate: Product Owner approval

2. Specification
   id: specification
   selected: create-user-stories
   agents: product-owner
   dependencies: idea

3. Architecture
   id: architecture
   selected: create-architecture-plan
   agents: rails-architect
   dependencies: specification
   gate: ADR Accepted for significant decisions

4. Implementation Plan
   id: implementation-plan
   selected: create-architecture-plan
   agents: rails-architect
   dependencies: architecture

5. Development
   id: development
   selected: create-api-endpoints, review-db-migrations, ponytail-review
   agents: backend-rails-developer, frontend-react-inertia-developer
   dependencies: implementation-plan

6. Testing
   id: testing
   selected: qa-plan, security-audit, ponytail-review
   omitted: review-rails-models:no matching paths
   agents: qa-engineer
   dependencies: development
   gate: QA sign-off, no BLOCKING findings, and no unaddressed over-engineering (ponytail-review)

7. Documentation
   id: documentation
   selected: document-module
   agents: documentation-writer
   dependencies: testing

8. Deployment
   id: deployment
   selected: release-checklist
   omitted: capistrano-review:no matching paths
   agents: aws-devops-engineer
   dependencies: documentation

Declared units: 14
Selected units: 12
Omitted units: 2
Execution units: 12
LLM calls performed: 0
```

**What those words mean:**

| Word | Meaning |
|------|---------|
| **id** | Stable phase name for `--only` / `--skip` (use this, not the label) |
| **selected** | Skills (or agents) the runner will actually call |
| **omitted** | Review skills skipped because their files are missing (0 tokens) |
| **Declared units** | Everything listed in the YAML |
| **Selected / Execution units** | What would spend model tokens |
| **gate** | Human yes/no after the phase. `--auto` still stops here |

If a skill is omitted and you **need** it (you are about to add those files):

```bash
rorcc workflow new-feature --plan --full    # select all 14; still 0 LLM calls
```

Then run (picks a backend):

```bash
rorcc workflow new-feature                  # Enter = run this phase, s = skip, q = quit
rorcc workflow new-feature --auto           # no Enter; one model turn per selected skill
rorcc workflow new-feature --auto --cloud   # same, using OpenAI/Anthropic
```

`--auto` does **not** approve gates and does **not** commit.

Resume later without redoing idea/spec:

```bash
rorcc workflow new-feature --only development,testing
```

`--only` treats phases you omitted as already done. `--skip deployment` skips
that phase and **blocks** anything that `depends_on` it.

---

## How to invoke (any platform)

| Platform | What you type |
|----------|----------------|
| **Cursor** | Agent mode: `Execute .ai/workflows/new-feature.yaml for "<feature>". Stop after each phase and wait for my approval. Delegate each phase to the matching subagent.` Attach `@.ai/workflows/new-feature.yaml`. |
| **Claude Code** | Same wording, or `/<skill>` phase by phase from `.claude/agents/` |
| **CLI preview** | `rorcc workflow <name> --plan` |
| **CLI run** | `rorcc workflow <name>` or `… --auto` (from a folder that contains `.ai/`) |

### What the CLI actually runs

Rules in [`.ai/standards/orchestration.md`](../../.ai/standards/orchestration.md):

1. **Skills are the execution unit.** If a phase lists `skills:`, those run in
   order. The phase's `agents:` stay as documentation — the CLI does **not**
   open a second chat with the specialist on top of the skill.
2. **Agents run only when there are no skills** (example: incident triage).
3. **`depends_on` is enforced.** A phase runs only if every dependency is
   `passed`. `skipped` / `failed` / `blocked` → this phase is `blocked` (no
   model call).
4. **Preflight is free.** Duplicate ids, missing skills/agents, bad
   `depends_on` → `workflow invalid` and exit **before** any LLM call.
5. **Router (0 tokens).** A `review-*` / `*-review` / `*-audit` skill with YAML
   `paths:` is omitted when none of those paths exist — unless the same phase
   also has a `create-*` skill (it will review what that create is about to
   write). `--full` turns the router off.
6. **Workflow cloud prompts are lean:** specialist `purpose` + `SKILL.md` +
   named templates. Standalone `rorcc skill` still sends the full standards dump.

**Parallel agents (Cursor only):** backend and frontend **may** run as two
Cursor `Task` subagents when the contract is already frozen (ADR + stories) and
the workstreams do not share files. The CLI stays sequential on purpose:
two parallel chats re-read the same context (more tokens) and can invent two
different APIs. Do not ask the CLI for parallel workers.

`--request` / `--size` / `--signals` classify once (heuristic, 0 LLM), then
honor `applies_when` on each phase. Omitted phases **pass** (vacuous) so
dependents are not blocked. Without these flags, behavior is unchanged
(path router only). `--full` and `--only` ignore `applies_when`.

Run state (after a real run, not `--plan`) is under `.rorcc/runs/<run-id>/`
(`state.tsv`, `metrics.tsv`, `summary.tsv`) — gitignored.

---

## Flag cheat sheet

| Flag | Effect | Use when |
|------|--------|----------|
| `--plan` | Parse + preflight + router. Print units. No model, no writes | Always first |
| `--auto` | No `[Enter]` per phase; one-shot reply per unit; **gates still ask** | You accept sequential one-shots |
| `--only id,id` | Run only those phase ids | You already finished earlier phases |
| `--skip id` | Skip those phases; dependents become `blocked` | You explicitly do not want a later phase |
| `--full` | Select every declared skill, even if paths are missing | Greenfield / you know the files will appear |
| `--request "…"` | Classify once, then honor `applies_when` | Adaptive `new-feature` (S/M/L/XL) |
| `--size S\|M\|L\|XL` | Override size (implies classification) | Heuristic is wrong |
| `--signals a,b` | Override risk signals (implies classification) | e.g. `--size S --signals auth_changed` |
| `--local` / `--cloud` | Backend (default is `RORCC_BACKEND` or local) | Local everyday; cloud for hard architecture |

Phase **ids** (copy these into `--only` / `--skip`, never the labels):

| Workflow | Phase ids |
|----------|-----------|
| `new-feature` | `idea`, `specification`, `architecture`, `implementation-plan`, `development`, `testing`, `documentation`, `deployment` |
| `aws-deployment` | `planning`, `infrastructure-review`, `security-review`, `deployment`, `validation`, `rollback-strategy` |
| `legacy-onboarding` | `discovery`, `inventory`, `risk-assessment`, `reverse-documentation`, `modernization-plan` |
| `production-incident` | `incident`, `triage`, `root-cause-analysis`, `fix`, `validation`, `release`, `postmortem` |

`--plan` counts **in this kit’s tree** (no `app/models`, no Capistrano/nginx files):

| Workflow | Declared | Selected | Typically omitted |
|----------|----------|----------|-------------------|
| `new-feature` | 14 | 12 | `review-rails-models`, `capistrano-review` |
| `aws-deployment` | 7 | 5 | `capistrano-review`, `nginx-puma-review` |
| `legacy-onboarding` | 7 | 7 | — |
| `production-incident` | 12 | 11 | `capistrano-review` |

---

## new-feature

**Phases:** Idea → Specification → Architecture → Implementation Plan → Development → Testing → Documentation → Deployment

| Phase | id | Skill(s) the CLI runs | Gate |
|-------|----|----------------------|------|
| Idea | `idea` | `create-feature-spec` → `docs/specs/` | Product Owner approval |
| Specification | `specification` | `create-user-stories` → `docs/stories/` | — |
| Architecture | `architecture` | `create-architecture-plan` → ADRs | ADR Accepted when significant |
| Implementation Plan | `implementation-plan` | `create-architecture-plan` (migration + rollback) | — |
| Development | `development` | `create-api-endpoints`, `review-db-migrations`, `ponytail-review` | — |
| Testing | `testing` | `qa-plan`, `review-rails-models`*, `security-audit`, `ponytail-review` | No BLOCKING; ponytail clean |
| Documentation | `documentation` | `document-module` | — |
| Deployment | `deployment` | `release-checklist`, `capistrano-review`* | — |

\* Omitted by the router when `app/models/**` or `config/deploy.rb` (etc.) do
not exist. In this kit’s own tree, `--plan` typically reports **14 declared /
12 selected**. With `--request`, `applies_when` can omit more (S copy → 3).

**Verification (done):** proportional DoD in `.ai/standards/orchestration.md` —
earn spec/ADR/docs/QA by size and signals; never skip safety. Branch
`feature/<ticket>-<slug>`.

**Cursor prompt:**

```
Execute .ai/workflows/new-feature.yaml for "stock transfer between warehouses".
Stop after each phase and wait for my approval before continuing.
```

---

## aws-deployment

**Phases:** Planning → Infrastructure Review → Security Review → Deployment → Validation (+ Rollback Strategy from planning)

Preview first: `rorcc workflow aws-deployment --plan` (this kit: **7 declared / 5 selected**).

| Phase | id | What the CLI runs | Gate / note |
|-------|----|-------------------|-------------|
| Planning | `planning` | skill `aws-deploy-plan` → `docs/deployments/plan-*.md` | — |
| Infrastructure Review | `infrastructure-review` | **agent only** `aws-devops-engineer` (no skill) | IAM, staging parity, IaC |
| Security Review | `security-review` | skill `security-audit` | — |
| Deployment | `deployment` | `capistrano-review`, `nginx-puma-review` (often both omitted here) | If both omit, the phase is vacuous **passed** |
| Validation | `validation` | **agent only** `qa-engineer` | Health, smoke, watch errors ~30 min |
| Rollback Strategy | `rollback-strategy` | **agent only** `aws-devops-engineer` | Depends on `planning` (not on `deployment`) |

**Verification:** Deploy plan approved, security sign-off, rollback documented, smoke green.

---

## legacy-onboarding

**Phases:** Discovery → Inventory → Risk → Reverse Documentation → Modernization Plan

Preview first: `rorcc workflow legacy-onboarding --plan` (this kit: **7 / 7**, nothing omitted).

Read-only on app code until the modernization plan is **approved**. Standard:
`.ai/standards/legacy-rails.md`. Skill: `reverse-document-legacy` (used in
discovery, inventory, risk, and reverse-documentation).

| Phase | id | Skill(s) | Gate |
|-------|----|----------|------|
| Discovery | `discovery` | `reverse-document-legacy` | Scope and access confirmed |
| Inventory | `inventory` | `reverse-document-legacy` | — |
| Risk Assessment | `risk-assessment` | `tech-debt-analysis`, `reverse-document-legacy`, `ponytail-audit` | — |
| Reverse Documentation | `reverse-documentation` | `reverse-document-legacy` | — |
| Modernization Plan | `modernization-plan` | `create-architecture-plan` | Plan approved **before** any behavior change |

**Verification:** System map + module audits + tech-debt register + retrospective
ADRs + approved modernization plan — no behavior change before that gate.

---

## production-incident

**Phases:** Incident → Triage → RCA → Fix (`hotfix/*`) → Validation → Release → Postmortem

Preview first: `rorcc workflow production-incident --plan` (this kit: **12 declared / 11 selected**).

Most phases are **agent-only** (no skill). Fix follows `.ai/standards/git-workflow.md`
(`hotfix/*` branch). There is **no** invented “hotfix skill”.

| Phase | id | What the CLI runs | Gate / note |
|-------|----|-------------------|-------------|
| Incident | `incident` | agent `aws-devops-engineer` | Incident commander assigned |
| Triage | `triage` | agents `aws-devops-engineer`, `backend-rails-developer` | — |
| Root Cause Analysis | `root-cause-analysis` | agents backend + architect + security | — |
| Fix | `fix` | agents `backend-rails-developer`, `aws-devops-engineer` | Branch `hotfix/*` |
| Validation | `validation` | agent `qa-engineer` | — |
| Release | `release` | skill `release-checklist` (+ `capistrano-review` if `config/deploy.rb` exists) | — |
| Postmortem | `postmortem` | agent `documentation-writer` | `docs/incidents/postmortem-*.md` |

**Verification:** Severity assigned, fix validated on staging, release checklist
run, postmortem under `docs/incidents/postmortem-*.md`.

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `no .ai/ framework found` | `cd` into the cloned repo or the installed project |
| `workflow not found` | Names are `new-feature`, `aws-deployment`, `legacy-onboarding`, `production-incident` |
| `workflow invalid` | Preflight failed (unknown skill/agent, bad `depends_on`). Read the `error:` lines; fix the YAML **before** running a model |
| Phase `blocked` | A dependency was `skipped` / `failed` / `blocked`. Re-run the dependency, or use `--only` if you already did that work outside the runner |
| Skill `omitted: … no matching paths` | Expected when those files do not exist. Need it anyway? `--full` |
| `--auto` still asks a question | That is a **gate**. Type `y` only if the gate text is actually satisfied |
| Agent skips gates (Cursor) | Remind: “stop after each phase; wait for approval” |
| Two specialists disagree on the API | Do not run backend + frontend in parallel until the ADR exists |
| Unsure which workflow | New work → `new-feature`; inherited app → `legacy-onboarding`; outage → `production-incident`; release only → `aws-deployment` |

---

## Related

- CLI reference: [../rorcc-cli.md](../rorcc-cli.md)
- Specialists matrix: [use-agents.md](use-agents.md)
- Developer notes: [../modules/workflow-runner.md](../modules/workflow-runner.md)
- Docs map: [../README.md](../README.md)
- User Manual hub: [../USER-MANUAL.md](../USER-MANUAL.md)

---

## Versión en español

# Ejecutar workflows de punta a punta

**Audiencia:** Quien usa RoR Command Center y quiere un proceso multiphase guiado.
**Objetivo:** Elegir workflow, previsualizarlo y correrlo (Cursor / Claude / `rorcc`).

**Antes:** entra a una carpeta que tenga `.ai/`. `--plan` no necesita Ollama ni API keys.

```bash
rorcc workflow new-feature --plan     # 0 llamadas a modelo; muestra selected / omitted
rorcc workflow new-feature            # Enter / s / q
rorcc workflow new-feature --auto     # un turno por skill; los gates siguen pidiendo sí
rorcc workflow new-feature --only development,testing
```

| Workflow | Cuándo |
|----------|--------|
| `new-feature` | Feature nueva de idea a deploy |
| `aws-deployment` | Release AWS con seguridad y rollback |
| `legacy-onboarding` | App Rails heredada — documentar antes de cambiar conducta |
| `production-incident` | Incidente en producción |

- Si hay `skills:`, el CLI **no** abre chats extra de `agents:` (evita pagar dos veces).
- Reviews sin archivos (`capistrano-review` sin `config/deploy.rb`) se **omiten**.
- `depends_on` se cumple: una fase skipped/failed **bloquea** a las siguientes.
- `--request` / `--size` / `--signals` clasifican una vez y aplican `applies_when`.
- Paralelo backend+frontend: solo en **Cursor Task** cuando el contrato ya está
  cerrado. El CLI es secuencial a propósito (menos tokens, menos APIs inventadas).

**Flags:** `--plan` (0 tokens) · `--auto` (un turno por skill; los gates piden `y`) ·
`--only id,id` (trata el resto como ya hecho) · `--skip id` (bloquea dependientes) ·
`--full` (no omitir reviews) · `--request` / `--size` / `--signals` (clasificación).

**IDs de `new-feature`:** `idea`, `specification`, `architecture`,
`implementation-plan`, `development`, `testing`, `documentation`, `deployment`.

**`--plan` en este repo (sin `app/models` ni Capistrano):**

| Workflow | Declaradas | Seleccionadas | Suele omitir |
|----------|------------|---------------|--------------|
| `new-feature` | 14 | 12 | `review-rails-models`, `capistrano-review` |
| `aws-deployment` | 7 | 5 | `capistrano-review`, `nginx-puma-review` |
| `legacy-onboarding` | 7 | 7 | — |
| `production-incident` | 12 | 11 | `capistrano-review` |

| Síntoma | Qué hacer |
|---------|-----------|
| `no .ai/ framework found` | `cd` a la carpeta que tiene `.ai/` |
| `workflow invalid` | Lee `error:`; no se llamó a ningún modelo |
| Fase `blocked` | Repite la dependencia, o `--only` si ya la hiciste fuera |
| `--auto` pregunta | Es un **gate**. Escribe `y` solo si el texto del gate se cumple |

Detalle de fases y troubleshooting: secciones en inglés arriba.
