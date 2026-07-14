> Language: English | [Español](#versión-en-español)

# Use the agents (the 8 specialists)

**Audience:** Anyone using RoR Command Center in a Rails project with any AI tool
(Cursor, Claude Code, Codex, Copilot, or the local `rorcc` CLI). You do **not**
need to know how the framework is built internally.
**Goal:** Know which specialist to invoke for a task, and exactly how to invoke
it on each platform.
**Last updated:** 2026-07-10

> This guide is about **using** the existing roles. To **create or compile** your
> own specialist, see [create-specialist-agent.md](create-specialist-agent.md).

---

## How invocation works (any platform)

An **agent** is a role defined in `.ai/agents/<id>.yaml` (with `delegation` for
discovery). A **skill** is a concrete task in `.ai/skills/<name>/SKILL.md`. You
pair them: pick the *role*, then point it at the *skill* and the relevant
*standards*.

| Platform | How you invoke an agent |
|----------|-------------------------|
| **Cursor** | Prefer the native subagent: `/<id>` or “use the `<id>` subagent…”. Adapters live in `.cursor/agents/<id>.md` and read `.ai/agents/<id>.yaml`. Fallback: `Act as the agent in .ai/agents/<id>.yaml` with `@`-mentions. |
| **Claude Code** | Run `claude`; invoke skills as slash commands (`/create-feature-spec`, `/qa-plan`, …). Agents in `.claude/agents/` read the same YAML. |
| **Codex / Copilot** | `AGENTS.md` / `.github/copilot-instructions.md` load automatically; reference the agent file in your prompt as in Cursor. |
| **Local CLI** | `rorcc agent <name>` (chat) · `rorcc skill <skill>` · `rorcc workflow <workflow>`. |

Every agent embeds the **collaboration protocol** (Question → Options → Decision
→ Draft → Approval) and the **Definition of Done** gates (tests, review, QA,
docs). They will ask before writing files.

---

## The 8 specialists — what, when, how

| Agent | Use it when you need to… | Pairs with skills |
|-------|--------------------------|-------------------|
| **product-owner** | Define scope, write a feature spec, break work into user stories with acceptance criteria | `create-feature-spec`, `create-user-stories` |
| **rails-architect** | Make architectural decisions, model data, write ADRs, review migrations & SQL | `create-architecture-plan`, `review-db-migrations`, `sql-review` |
| **backend-rails-developer** | Implement models, controllers, services, jobs, API endpoints (+ their RSpec) | `create-api-endpoints`, `review-rails-models`, `ocr-pipeline`, `whatsapp-integration` |
| **frontend-react-inertia-developer** | Build UI with Hotwire / React + Inertia, own UX states and accessibility | `create-ux-spec` |
| **aws-devops-engineer** | Plan/execute AWS deploys, CI/CD, releases, server config | `aws-deploy-plan`, `capistrano-review`, `nginx-puma-review`, `release-checklist` |
| **qa-engineer** | Write a QA plan, review a PR/diff, flag over-engineering before merge | `qa-plan`, `ponytail-review`, `ponytail-audit`, `ponytail-debt` |
| **documentation-writer** | Document a module, write a user guide, **record a video demo**, reverse-document legacy code | `document-module`, `document-user-guide`, `record-user-demo`, `reverse-document-legacy` |
| **security-reviewer** | Audit auth, secrets, IAM, input handling; produce a remediation report | `security-audit` |

> Not sure which to pick? Start with the **workflow**:
> [.ai/workflows/new-feature.yaml](../../.ai/workflows/new-feature.yaml) runs the
> right agents in order. Human how-to for all four workflows:
> [run-workflows.md](run-workflows.md).

---

## Copy-paste recipes (Cursor)

**Spec a feature (product-owner):**

```
/product-owner Follow .ai/skills/create-feature-spec/SKILL.md for "<feature>".
Ask me questions first, then save the spec to docs/specs/.
```

**Review a model against standards (qa-engineer):**

```
/qa-engineer Review app/models/<model>.rb against .ai/standards/development.md
and .ai/standards/security.md. List findings by severity; don't edit files yet.
```

**Record a user video demo (documentation-writer + record-user-demo):**

```
/documentation-writer Follow .ai/skills/record-user-demo/SKILL.md to create a
captioned video demo of "<feature>". Read the demo credentials from the
environment (<APP>_DEMO_EMAIL / <APP>_DEMO_PASSWORD), drive the real dev app
with Playwright, output public/video/<feature>.{webm,vtt}, and embed it in the
help page. Ask before writing files.
```

> Prerequisites for the demo recipe: app running, a seeded demo user, Playwright
> installed (`npx playwright install chromium`, or baked into the Docker image),
> and credentials in `.env.example`. The run drives the **development** app and
> may create real records — never point it at production. Full detail:
> `.ai/skills/record-user-demo/SKILL.md`.

**Run the full feature workflow:**

```
Run .ai/workflows/new-feature.yaml for "<feature>". Stop after each phase and
wait for my approval. Delegate each phase to the matching Cursor subagent.
```

**Fallback (Ask mode / no subagent):**

```
Act as the agent in .ai/agents/product-owner.yaml and follow
.ai/skills/create-feature-spec/SKILL.md for "<feature>".
```

---

## Verify it worked

- [ ] The agent acknowledged its role and the skill/standards before acting.
- [ ] It asked clarifying questions and showed a draft before writing files
      (collaboration protocol).
- [ ] Output landed where the skill says (e.g. `docs/specs/`,
      `public/video/<feature>.webm`).

## Troubleshooting

| Symptom | Cause / Fix |
|---------|-------------|
| Agent ignores standards | Router not loaded — `@`-mention the agent and skill, or check `.cursor/rules/ai-index.mdc`. |
| Agent edits without asking | You're in Agent mode — ask it to "propose before writing" or plan in Ask mode. |
| `no .ai/ framework found` (CLI) | Run inside a folder containing `.ai/` (a `rorcc init` project or the cloned repo). |
| Don't know which agent fits | Run the workflow (`.ai/workflows/new-feature.yaml`); it sequences the agents. |

## Related

- User manual: [docs/USER-MANUAL.md](../USER-MANUAL.md) (§4 Uso diario)
- Create/compile your own specialist: [create-specialist-agent.md](create-specialist-agent.md)
- Agent definitions: `.ai/agents/` · Skills: `.ai/skills/` · Workflows: `.ai/workflows/`
- Collaboration protocol: `.ai/standards/collaboration.md`

---

## Versión en español

**Audiencia:** cualquiera que use RoR Command Center en un proyecto Rails con
cualquier herramienta de IA (Cursor, Claude Code, Codex, Copilot o el CLI local
`rorcc`). **No** necesitas conocer cómo está construido el framework por dentro.
**Objetivo:** saber qué especialista invocar para cada tarea y cómo invocarlo en
cada plataforma.
**Última actualización:** 2026-07-10

> Esta guía trata de **usar** los roles existentes. Para **crear o compilar** tu
> propio especialista, ve a [create-specialist-agent.md](create-specialist-agent.md).

### Cómo funciona la invocación (cualquier plataforma)

Un **agente** es un rol definido en `.ai/agents/<id>.yaml` (con `delegation` para
discovery). Una **skill** es una tarea concreta en `.ai/skills/<nombre>/SKILL.md`.
Se combinan: eliges el *rol*, luego lo apuntas a la *skill* y a los *standards*
relevantes.

| Plataforma | Cómo invocas un agente |
|------------|------------------------|
| **Cursor** | Prefiere el subagent nativo: `/<id>` o “usa el subagent `<id>`…”. Adapters en `.cursor/agents/<id>.md` leen `.ai/agents/<id>.yaml`. Fallback: `Actúa como el agent en .ai/agents/<id>.yaml` con `@`-menciones. |
| **Claude Code** | Ejecuta `claude`; invoca skills como slash commands (`/create-feature-spec`, `/qa-plan`, …). Agents en `.claude/agents/` leen el mismo YAML. |
| **Codex / Copilot** | `AGENTS.md` / `.github/copilot-instructions.md` se cargan solos; referencia el archivo del agente en tu prompt igual que en Cursor. |
| **CLI local** | `rorcc agent <nombre>` (chat) · `rorcc skill <skill>` · `rorcc workflow <workflow>`. |

Cada agente lleva incorporado el **protocolo de colaboración** (Pregunta →
Opciones → Decisión → Borrador → Aprobación) y los gates de la **Definition of
Done** (tests, revisión, QA, docs). Preguntarán antes de escribir archivos.

### Los 8 especialistas — qué, cuándo, cómo

| Agente | Úsalo cuando necesites… | Skills que combina |
|--------|--------------------------|--------------------|
| **product-owner** | Definir alcance, redactar un feature spec, dividir el trabajo en historias con criterios de aceptación | `create-feature-spec`, `create-user-stories` |
| **rails-architect** | Tomar decisiones de arquitectura, modelar datos, escribir ADRs, revisar migraciones y SQL | `create-architecture-plan`, `review-db-migrations`, `sql-review` |
| **backend-rails-developer** | Implementar modelos, controladores, servicios, jobs, endpoints de API (+ sus RSpec) | `create-api-endpoints`, `review-rails-models`, `ocr-pipeline`, `whatsapp-integration` |
| **frontend-react-inertia-developer** | Construir UI con Hotwire / React + Inertia, dueño de los estados de UX y la accesibilidad | `create-ux-spec` |
| **aws-devops-engineer** | Planear/ejecutar deploys en AWS, CI/CD, releases, config de servidores | `aws-deploy-plan`, `capistrano-review`, `nginx-puma-review`, `release-checklist` |
| **qa-engineer** | Escribir un plan de QA, revisar un PR/diff, marcar sobre-ingeniería antes de hacer merge | `qa-plan`, `ponytail-review`, `ponytail-audit`, `ponytail-debt` |
| **documentation-writer** | Documentar un módulo, escribir una guía de usuario, **grabar un demo en video**, documentar código legacy | `document-module`, `document-user-guide`, `record-user-demo`, `reverse-document-legacy` |
| **security-reviewer** | Auditar auth, secretos, IAM, manejo de input; producir un reporte de remediación | `security-audit` |

> ¿No sabes cuál elegir? Empieza por el **workflow**:
> `.ai/workflows/new-feature.yaml` ejecuta los agentes correctos en orden
> (product-owner → rails-architect → developers → qa-engineer →
> documentation-writer).

### Recetas copy-paste (Cursor)

**Redactar un feature spec (product-owner):**

```
/product-owner Sigue .ai/skills/create-feature-spec/SKILL.md para "<feature>".
Hazme preguntas primero; luego guárdalo en docs/specs/.
```

**Revisar un modelo contra los standards (qa-engineer):**

```
/qa-engineer Revisa app/models/<model>.rb contra .ai/standards/development.md y
.ai/standards/security.md. Lista los hallazgos por severidad; no edites archivos
todavía.
```

**Grabar un demo en video de usuario (documentation-writer + record-user-demo):**

```
/documentation-writer Sigue .ai/skills/record-user-demo/SKILL.md para crear un
demo en video con subtítulos de "<feature>". Lee las credenciales del entorno
(<APP>_DEMO_EMAIL / <APP>_DEMO_PASSWORD), conduce la app real de desarrollo con
Playwright, genera public/video/<feature>.{webm,vtt} e incrústalo en la página de
ayuda. Pregunta antes de escribir archivos.
```

> Prerrequisitos de la receta del demo: app corriendo, usuario demo en el seed,
> Playwright instalado (`npx playwright install chromium`, o dentro de la imagen
> Docker) y credenciales en `.env.example`. La corrida conduce la app de
> **desarrollo** y puede crear registros reales — nunca la apuntes a producción.
> Detalle completo: `.ai/skills/record-user-demo/SKILL.md`.

**Ejecutar el workflow completo de feature:**

```
Ejecuta .ai/workflows/new-feature.yaml para "<feature>". Detente tras cada fase y
espera mi aprobación. Delega cada fase al subagent Cursor correspondiente.
```

**Fallback (modo Ask / sin subagent):**

```
Actúa como el agent en .ai/agents/product-owner.yaml y sigue
.ai/skills/create-feature-spec/SKILL.md para "<feature>".
```

### Verifica que funcionó

- [ ] El agente reconoció su rol y la skill/standards antes de actuar.
- [ ] Hizo preguntas y mostró un borrador antes de escribir archivos (protocolo
      de colaboración).
- [ ] La salida quedó donde indica la skill (p. ej. `docs/specs/`,
      `public/video/<feature>.webm`).

### Solución de problemas

| Síntoma | Causa / Solución |
|---------|------------------|
| El agente ignora los standards | El router no se cargó — `@`-menciona el agente y la skill, o revisa `.cursor/rules/ai-index.mdc`. |
| El agente edita sin preguntar | Estás en modo Agent — pídele "propón antes de escribir" o planifica en modo Ask. |
| `no .ai/ framework found` (CLI) | Ejecuta dentro de una carpeta con `.ai/` (un proyecto `rorcc init` o el repo clonado). |
| No sabes qué agente encaja | Ejecuta el workflow (`.ai/workflows/new-feature.yaml`); secuencia los agentes. |

### Relacionado

- Manual de usuario: [docs/USER-MANUAL.md](../USER-MANUAL.md) (§4 Uso diario)
- Crear/compilar tu propio especialista: [create-specialist-agent.md](create-specialist-agent.md)
- Definiciones de agentes: `.ai/agents/` · Skills: `.ai/skills/` · Workflows: `.ai/workflows/`
- Protocolo de colaboración: `.ai/standards/collaboration.md`
