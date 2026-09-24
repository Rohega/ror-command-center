> Language: English | [Español](#versión-en-español)

# ADR-0011: Next.js is a stack id, one workflow, one implementer

## Status

Accepted

## Date

2026-09-24

## Context

[ADR-0010](adr-0010-stack-core.md) names `rails` and `unspecified` and does not add a stack. Phase 6 adds Next.js only. Python and a standalone React app stay out.

## Decision

`_stack_id` returns `nextjs` when `next.config.js`, `next.config.mjs`, or `next.config.ts` exists and the tree is not already Rails. Rails markers win.

`.ai/stacks/nextjs/STANDARDS` lists `nextjs.md`. The workflow is `next-feature`. Its only implementer is `frontend-react-inertia-developer`. `rorcc init --next <dir>` writes `next.config.mjs` and installs the framework. It does not run npm.

`new-feature` and its selected units stay as they are.

## Alternatives Considered

| Option | Pros | Cons |
|--------|------|------|
| Detect, one workflow, one existing agent (chosen) | A Next tree can run `--plan`. Rails selection is unchanged. | No full Next application generator. |
| A new specialist per stack | Clear ownership. | Eight more roles for one stack. |
| Wait for a client project | Less code. | The scaffold is only the marker. |

## Consequences

### Positive

- `next-feature --plan` selects one implementer.
- A Rails app is still `rails` when a Rails marker is present.

### Negative

- `init --next` does not install npm packages. The app does not run until someone installs Next.

## Compliance

- Standards: [`.ai/standards/orchestration.md`](../../.ai/standards/orchestration.md)
- Stories blocked until Accepted: none

---

## Versión en español

# ADR-0011: Next.js es un stack, un workflow y un implementador

## Estado

Accepted

## Decisión

Si hay `next.config.*` y el árbol no es Rails, el id es `nextjs`. El workflow es `next-feature` y el único implementador es `frontend-react-inertia-developer`. `rorcc init --next` escribe el marcador e instala el framework. No corre npm. `new-feature` no cambia.
