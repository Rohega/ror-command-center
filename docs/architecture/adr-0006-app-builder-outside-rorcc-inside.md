> Language: English | [Español](#versión-en-español)

# ADR-0006: App builder outside, Command Center inside

## Status

Accepted

## Date

2026-09-24

## Context

RoR Command Center is an engineering kit: specialists, skills, and a deterministic workflow runner. A non-technical person cannot start from “I want an app” and reach a gated Rails change. Open app builders (Dyad, bolt.diy) cover that outer loop with one model that writes until a preview looks right. They do not run Rails, and they do not keep a human gate in front of a specialist workflow.

`docs/architecture/adr-0001` through `adr-0005` belong to the warehouse example. This ADR is a decision about the kit.

## Decision

Add a thin builder in front of the existing `new-feature` workflow. Do not fork Dyad or bolt.diy. Do not let a model choose the next phase. Do not split `.ai/` into `core/` and `stacks/` until a second stack has a real project.

The sequence is fixed:

| Phase | Scope | When it may start |
|-------|--------|-------------------|
| 1 | `rorcc builder`: fixed questions, plain-language plan, human accept, then `new-feature` | Now. Design: [docs/design/app-builder.md](../design/app-builder.md) |
| 2 | File and shell actions on the real project tree, with git as the undo checkpoint | After phase 1 writes code through the current workflow |
| 3 | Structured security pass at the close, reusing `security-reviewer` | After phase 2, and only when size or signals already require it |
| 4 | Preview of the server `docker compose` already starts | After phases 1–3 fail loudly without a UI |
| 5 | Split stack-agnostic standards from the Rails stack | After the builder is in use. No behavior change |
| 6 | A Next.js stack | Only when a real project asks for it |
| 7 | A desktop or web shell that calls `rorcc` | Product decision. Not this repository |

Phases 2–7 each have an accepted ADR: [0007](adr-0007-action-runner.md), [0008](adr-0008-security-pass.md), [0009](adr-0009-preview.md), [0010](adr-0010-stack-core.md), [0011](adr-0011-next-stack.md), [0012](adr-0012-external-shell.md). This ADR keeps the order. It does not replace those decisions.

Constraints on every phase:

- Do not vendor prompts from Dyad or bolt.diy.
- `router.sh` stays at zero model tokens. `orchestration.md` still forbids a model picking the phase.
- Workflow context stays lean: specialist purpose, skill, named templates.
- The engineer README stays the primary entry. The builder is a mode, not a replacement.
- “The preview looks fine” does not close work that the proportional Definition of Done still requires.

## Alternatives Considered

| Option | Pros | Cons |
|--------|------|------|
| Builder mode on the current Rails workflow (chosen) | Uses `new-feature`, gates, and the router. Smallest change that a non-engineer can start. | No preview and no second stack in the first cut. |
| Split `core/` and `stacks/` first | Matches the long-term diagram. | Duplicates standards before a second client exists. |
| Action protocol first | Matches bolt.diy’s useful mechanism. | Builds a runner for a shell that does not talk to anyone yet. |
| Fork Dyad or bolt.diy as the product | Preview and chat already exist. | WebContainers cannot run Rails. Electron would own the kit. `src/pro` in Dyad is not Apache-2.0. |

## Consequences

### Positive

- One entry point can ask a few questions and hand a bounded request to the workflow that already exists.
- Later phases have a written order, so a preview or a Next stack cannot jump the queue.
- The deterministic router and the proportional Definition of Done stay in force.

### Negative

- Two audiences share one repository. The builder must not become the only documented path.
- Phase 1 does not produce a running preview. Callers who expect Dyad will not get it yet.
- The detail of phases 2–7 lives in ADR-0007 through ADR-0012, not in this sequence table.

## Compliance

- Standards: [`.ai/standards/orchestration.md`](../../.ai/standards/orchestration.md), [`.ai/standards/collaboration.md`](../../.ai/standards/collaboration.md), [`.ai/standards/minimalism.md`](../../.ai/standards/minimalism.md), [`.ai/standards/documentation.md`](../../.ai/standards/documentation.md)
- Feature spec and user stories: waived. This decision changes the kit’s entry, not a Rails product feature. The design is the plan.
- Stories blocked until Accepted: none. Implementation of phase 1 still follows [docs/design/app-builder.md](../design/app-builder.md).

---

## Versión en español

# ADR-0006: App builder por fuera, Command Center por dentro

## Estado

Accepted

## Fecha

2026-09-24

## Contexto

RoR Command Center es un kit de ingeniería: especialistas, skills y un runner de workflows determinista. Una persona no técnica no puede partir de “quiero una app” y llegar a un cambio Rails con gate. Los app builders abiertos (Dyad, bolt.diy) cubren ese bucle exterior con un solo modelo que escribe hasta que el preview se ve bien. No corren Rails y no dejan un gate humano delante de un workflow de especialistas.

`adr-0001` a `adr-0005` son del ejemplo warehouse. Este ADR es del kit.

## Decisión

Añadir un builder delgado delante del workflow `new-feature`. No forkear Dyad ni bolt.diy. Un modelo no elige la fase. No partir `.ai/` en `core/` y `stacks/` hasta que un segundo stack tenga un proyecto real.

La secuencia queda fija: fase 1 es `rorcc builder`. Las fases 2 a 7 ya tienen diseño aceptado: [ADR-0007](adr-0007-action-runner.md), [ADR-0008](adr-0008-security-pass.md), [ADR-0009](adr-0009-preview.md), [ADR-0010](adr-0010-stack-core.md), [ADR-0011](adr-0011-next-stack.md) y [ADR-0012](adr-0012-external-shell.md). Este ADR conserva el orden. No sustituye esas decisiones. El diseño de la fase 1 sigue en [docs/design/app-builder.md](../design/app-builder.md).

En todas las fases: no se copian prompts, el router sigue a cero tokens, el contexto del workflow sigue magro, el README del ingeniero sigue siendo la entrada principal, y un preview verde no cierra el Definition of Done.

## Alternativas

La opción elegida es el modo builder sobre el workflow Rails actual. Se descartó partir stacks primero, construir el protocolo de acciones primero, y forkear Dyad o bolt.diy. Pros y contras están en la tabla de la versión en inglés.

## Consecuencias

A favor: una entrada puede hacer pocas preguntas y entregar un pedido acotado al workflow que ya existe. En contra: dos audiencias en un repo. El detalle de las fases 2 a 7 está en los ADR-0007 a ADR-0012.

## Cumplimiento

Spec e historias: no aplican. Esto cambia la entrada del kit, no una feature de una app Rails. El diseño es el plan.
