> Language: English | [Español](#versión-en-español)

# Run workflows end-to-end

**Audience:** Anyone using RoR Command Center who wants a guided multi-phase
process (idea → ship, deploy, legacy, incident) without inventing steps.
**Goal:** Know which workflow to pick, how to start it on Cursor / Claude / `rorcc`,
and what “done” means at each gate.
**Last updated:** 2026-07-14

> Canonical YAML lives in `.ai/workflows/`. This page is the human how-to; agents
> should still **read** the YAML for phase details.

---

## When to use which workflow

| Workflow | File | Use when… |
|----------|------|-----------|
| **new-feature** | `.ai/workflows/new-feature.yaml` | Building a new product capability from idea through deploy |
| **aws-deployment** | `.ai/workflows/aws-deployment.yaml` | Planning/executing an AWS release with security + rollback |
| **legacy-onboarding** | `.ai/workflows/legacy-onboarding.yaml` | Inheriting a Rails app with weak/missing docs — document before changing behavior |
| **production-incident** | `.ai/workflows/production-incident.yaml` | Production breakage — triage → fix → release → postmortem |

You do **not** need a workflow for a one-line fix; use a single skill + agent
([use-agents.md](use-agents.md)).

---

## How to invoke (any platform)

| Platform | Command / prompt |
|----------|------------------|
| **Cursor** | Agent mode: `Execute .ai/workflows/<name>.yaml for "<context>". Stop after each phase and wait for my approval. Delegate each phase to the matching subagent.` |
| **Claude Code** | Same wording, or adopt agents from `.claude/agents/` / `@.ai/agents/<id>.yaml` phase by phase |
| **Local CLI** | `rorcc workflow <name>` (e.g. `rorcc workflow new-feature`) — run from a directory that contains `.ai/` |

Always attach the YAML with `@.ai/workflows/<name>.yaml` when the tool supports it.

---

## new-feature

**Phases:** Idea → Specification → Architecture → Implementation Plan → Development → Testing → Documentation → Deployment  

| Phase | Agent | Skill / notes | Gate |
|-------|-------|---------------|------|
| Idea | product-owner | `create-feature-spec` → `docs/specs/` | PO approval |
| Specification | product-owner | `create-user-stories` → `docs/stories/` | — |
| Architecture | rails-architect | `create-architecture-plan` → ADRs | ADR Accepted when significant |
| Implementation Plan | rails-architect | migration + rollback plan | — |
| Development | backend + frontend | APIs, migrations, `ponytail-review` | — |
| Testing | qa-engineer | `qa-plan`, reviews, `security-audit` | No BLOCKING; ponytail clean |
| Documentation | documentation-writer | `document-module` (+ user-guide if UX) | — |
| Deployment | aws-devops-engineer | `release-checklist`, Capistrano/Kamal as needed | — |

**Verification (done):** DoD checklist in `.cursor/rules/workflow-gates.mdc` —
RSpec critical paths, review, QA, docs, branch `feature/<ticket>-<slug>`.

**Sample prompt:**

```
Execute .ai/workflows/new-feature.yaml for "stock transfer between warehouses".
Stop after each phase and wait for my approval before continuing.
```

---

## aws-deployment

**Phases:** Planning → Infrastructure Review → Security Review → Deployment → Validation (+ Rollback Strategy from planning)

| Phase | Agent | Focus |
|-------|-------|-------|
| Planning | aws-devops-engineer | `aws-deploy-plan` → `docs/deployments/plan-*.md` |
| Infrastructure Review | aws-devops-engineer | IAM, staging parity, IaC |
| Security Review | security-reviewer | `security-audit` |
| Deployment | aws-devops-engineer | Capistrano / nginx-puma as relevant |
| Validation | qa-engineer | Health, smoke, watch errors ~30 min |
| Rollback Strategy | aws-devops-engineer | Triggers, commands, RTO (required) |

**Verification:** Deploy plan approved, security sign-off, rollback documented, smoke green.

---

## legacy-onboarding

**Phases:** Discovery → Inventory → Risk → Reverse Documentation → Modernization Plan  

Read-only on app code until the modernization plan is **approved**. Standard:
`.ai/standards/legacy-rails.md`. Skill: `reverse-document-legacy`.

**Verification:** System map + module audits + tech-debt register + retrospective
ADRs + approved modernization plan — no behavior change before that gate.

---

## production-incident

**Phases:** Incident → Triage → RCA → Fix (`hotfix/*`) → Validation → Release → Postmortem  

**Verification:** Severity assigned, fix validated on staging, release checklist
run, postmortem under `docs/incidents/postmortem-*.md`.

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Agent skips gates | Remind: “stop after each phase; wait for approval” |
| Wrong specialist | Point at the phase row in the YAML or this guide |
| `rorcc workflow` → no `.ai/` | `cd` into the cloned framework or an installed project |
| Unsure which workflow | New work → `new-feature`; inherited app → `legacy-onboarding`; outage → `production-incident`; release only → `aws-deployment` |

---

## Related

- Specialists matrix: [use-agents.md](use-agents.md)
- Docs map: [../README.md](../README.md)
- User Manual hub: [../USER-MANUAL.md](../USER-MANUAL.md)

---

## Versión en español

# Ejecutar workflows de punta a punta

**Audiencia:** Quien usa RoR Command Center y quiere un proceso multiphase guiado.
**Objetivo:** Elegir workflow, invocarlo (Cursor / Claude / `rorcc`) y saber qué
cuenta como “listo” en cada gate.

| Workflow | Cuándo |
|----------|--------|
| `new-feature` | Feature nueva de idea a deploy |
| `aws-deployment` | Release AWS con seguridad y rollback |
| `legacy-onboarding` | App Rails heredada — documentar antes de cambiar conducta |
| `production-incident` | Incidente en producción |

Invocación Cursor/Claude: ejecuta el YAML, detente en cada fase, espera
aprobación. CLI: `rorcc workflow <nombre>` dentro de un directorio con `.ai/`.

Detalle de fases y gates: secciones en inglés arriba (mismas tablas y YAML).
