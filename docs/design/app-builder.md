> Language: English | [Español](#versión-en-español)

# Technical Design: App builder

**Status:** Approved for phase 1. Phases 2–7 are held, not designed.  
**Author:** Rails Architect  
**Date:** 2026-09-24  
**ADR:** [ADR-0006](../architecture/adr-0006-app-builder-outside-rorcc-inside.md)

---

## Overview

Phase 1 is a command, `rorcc builder`, that runs in a project which already has `.ai/`. It asks a fixed set of questions, writes a plain-language plan, and on an explicit accept runs `rorcc workflow new-feature` with size and signals already set. It does not add a UI, a second stack, or an action runner.

## Requirements

- A person can describe an app change in one sentence and answer at most five questions.
- No file in the target app is written before the person accepts the plan.
- Accept maps answers onto the existing classifier outputs (`size` plus the signals in `.ai/standards/orchestration.md`) and then calls the current workflow.
- Reject or quit leaves the target app unchanged except for the plan file, which stays as a draft.
- The closing line of a finished run is one sentence in the person’s language. The workflow’s own artifacts stay as they are today.

## Architecture

```text
rorcc builder
  → fixed questions (no model)
  → plan file
  → human accept | revise | quit
  → rorcc workflow new-feature --size … --signals …
```

The model, if one is configured, is used only inside the workflow units that already call it. The questionnaire and the size/signal mapping are shell, same as `classify.sh`.

### Components

| Component | Responsibility | Location |
|-----------|----------------|----------|
| `builder` command | Ask, write the plan, accept, dispatch | `lib/rorcc/builder.sh`, dispatched from `cli/rorcc` |
| Plan file | The draft the person accepts | `<project>/docs/plans/builder-<utc>.md` |
| Workflow runner | Unchanged. Receives `--size` and `--signals` | `lib/rorcc/workflow.sh` |

`cli/rorcc` gains one arm: `builder`. The interactive menu does not gain an item in phase 1. Engineers keep `rorcc workflow`.

## Data Model

No database. The plan file is markdown:

```markdown
# Builder plan

- Request: …
- Who uses it: …
- Data: …
- Sign-in: …
- Done when: …

## Routing

- size: M
- signals: user_behavior_changed
```

The Routing section is the contract `builder.sh` parses. Prose above it is for the person.

## API / Interface

```bash
rorcc builder
rorcc builder --request "I want a page where staff mark an order as packed"
```

Questions, in order, skipped when the request already answers them:

1. Who uses this, in one role name?
2. Does it store or change data? (yes / no)
3. Does it sign someone in or check a permission? (yes / no)
4. Is this a new area of the app, or a change to one that exists? (new / change)
5. What does “done” look like, in one sentence?

Mapping, first match wins for size:

| Answers | size | signals |
|---------|------|---------|
| Sign-in or permission is yes | at least M | `auth_changed` |
| Stores or changes data is yes | at least M | `database_changed` |
| “New area” | L | `user_behavior_changed` |
| Otherwise | M | `user_behavior_changed` if the request names a screen or a flow; else none |

Size only moves up, never down. Phase 1 never emits `architecture_changed` or `infrastructure_changed`. Those wait for a later phase that can mean them.

Accept runs, from the project root:

```bash
rorcc workflow new-feature --size <size> --signals <csv> --request "<original sentence>"
```

`--plan` on the builder prints the questions, the plan path, and the workflow command. It does not call a model and does not write the plan.

## Security

- Authentication: none added. The builder does not collect secrets. A question answer that looks like a token or a password is rejected and asked again.
- Authorization: unchanged. Authz work is whatever `new-feature` already does when `auth_changed` is set.
- Data classification: the plan file is project documentation. It must not contain credentials.

## Testing Strategy

- Unit: shell tests for the mapping table and for “no write before accept”. Follow the style of the existing `tests/` scripts.
- Integration: `rorcc builder --plan` from a fixture project that contains `.ai/` prints the workflow command and creates no plan file.
- Manual: one accept path against `examples/` or a scratch Rails app, stopped at the workflow’s first human gate. Do not auto-approve gates.

## Rollout

- Feature flag: no. The command is opt-in.
- Migration order: none.
- Docs in the same change as the command: a short subsection in [docs/rorcc-cli.md](../rorcc-cli.md). Not in phase 1’s design-only commit.

## Later phases (held)

Do not implement these from this document. Open an ADR when a phase starts if the decision is architectural.

| Phase | Intent | Done when | Constraint |
|-------|--------|-----------|------------|
| 2 | Actions `file` and `shell` on the project tree. Decision: [ADR-0007](../architecture/adr-0007-action-runner.md). | A failed action leaves the tree at the checkpoint. | No WebContainer. No new snapshot store. |
| 3 | Structured security findings. Decision: [ADR-0008](../architecture/adr-0008-security-pass.md). | Findings cite files the pass opened. | Runs only when the proportional DoD already requires security. |
| 4 | Preview refresh and restart. Decision: [ADR-0009](../architecture/adr-0009-preview.md). | The person is not told to type a shell command for those two. | Preview is not the Definition of Done. |
| 5 | Stack id on the path router. Decision: [ADR-0010](../architecture/adr-0010-stack-core.md). | `rorcc workflow new-feature --plan` in a Rails app selects the same units as before. | No new stack in this phase. |
| 6 | Next.js stack id, `next-feature`, one implementer. Decision: [ADR-0011](../architecture/adr-0011-next-stack.md). | `next-feature --plan` selects `frontend-react-inertia-developer`. | Python and standalone React are out of scope. |
| 7 | External shell contract. Decision: [ADR-0012](../architecture/adr-0012-external-shell.md). | The shell is a separate repo. | It does not vendor this tree. |

## Open Questions

- [ ] Where shell tests for `lib/rorcc/*.sh` live today, and whether phase 1 adds the first builder test beside `tests/smoke.sh`.
- [ ] Whether `--request` alone may skip question 5 when the sentence already states done. Default in phase 1: still ask question 5.

---

## Versión en español

# Diseño técnico: App builder

**Estado:** Aprobado para la fase 1. Las fases 2 a 7 están retenidas, sin diseño.  
**Fecha:** 2026-09-24  
**ADR:** [ADR-0006](../architecture/adr-0006-app-builder-outside-rorcc-inside.md)

## Resumen

La fase 1 es el comando `rorcc builder`, en un proyecto que ya tiene `.ai/`. Hace preguntas fijas, escribe un plan en lenguaje llano y, si la persona acepta, lanza `rorcc workflow new-feature` con el tamaño y las señales ya puestos. No añade UI, ni otro stack, ni un runner de acciones.

## Contrato

- Como máximo cinco preguntas. Ningún archivo de la app se escribe antes de aceptar.
- Aceptar traduce las respuestas a `size` y signals, y llama al workflow actual.
- Rechazar o salir no toca la app, salvo el archivo de plan en borrador.
- El cierre es una frase. Los artefactos del workflow siguen como hoy.

El modelo, si hay uno, solo corre dentro de las unidades del workflow que ya lo llaman. El cuestionario y el mapeo son shell, igual que `classify.sh`.

## Piezas

| Pieza | Dónde |
|-------|--------|
| Comando `builder` | `lib/rorcc/builder.sh`, despachado desde `cli/rorcc` |
| Plan | `<proyecto>/docs/plans/builder-<utc>.md` |
| Runner | `lib/rorcc/workflow.sh`, sin cambios de comportamiento |

El menú interactivo no gana una entrada en la fase 1.

## Preguntas y mapeo

1. ¿Quién lo usa, con un solo rol?
2. ¿Guarda o cambia datos? (sí / no)
3. ¿Alguien inicia sesión o se comprueba un permiso? (sí / no)
4. ¿Es un área nueva o un cambio de una que ya existe? (nueva / cambio)
5. ¿Qué es “listo”, en una frase?

| Respuestas | size | signals |
|------------|------|---------|
| Sesión o permiso = sí | como mínimo M | `auth_changed` |
| Guarda o cambia datos = sí | como mínimo M | `database_changed` |
| Área nueva | L | `user_behavior_changed` |
| El resto | M | `user_behavior_changed` si el pedido nombra una pantalla o un flujo; si no, ninguna |

El tamaño solo sube. La fase 1 no emite `architecture_changed` ni `infrastructure_changed`.

Aceptar ejecuta `rorcc workflow new-feature --size … --signals … --request "…"`. `rorcc builder --plan` muestra el comando y no escribe el plan ni llama a un modelo.

## Seguridad y pruebas

No se piden secretos. Una respuesta que parece un token se rechaza. Las pruebas de shell cubren la tabla de mapeo y “no escribir antes de aceptar”. `rorcc builder --plan` en un proyecto con `.ai/` no crea el archivo de plan.

## Fases posteriores

No se implementan desde este documento. Hace falta un ADR al abrir cada fase si la decisión es de arquitectura. La tabla de la versión en inglés fija intención, criterio de cierre y restricción de las fases 2 a 7.

## Preguntas abiertas

- Dónde viven hoy las pruebas de `lib/rorcc/*.sh`, y si la fase 1 añade la primera junto a `tests/smoke.sh`.
- Si `--request` puede saltar la pregunta 5 cuando la frase ya dice qué es “listo”. En la fase 1, por defecto, se pregunta igual.
