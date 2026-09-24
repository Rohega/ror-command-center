> Language: English | [Español](#versión-en-español)

# ADR-0010: Name the stack without changing what the router selects

## Status

Accepted

## Date

2026-09-24

## Context

[ADR-0006](adr-0006-app-builder-outside-rorcc-inside.md) holds phase 5 until preview exists. Phase 4 is merged. Standards that apply to any stack (collaboration, security, testing) live in the same directory as Rails-only ones (Hotwire, Devise, ActiveAdmin). The path router selects skills from project files. A Rails app must keep the same `new-feature --plan` selection. This phase adds no second stack.

## Decision

`.ai/stacks/core/STANDARDS` lists the stack-agnostic standard files. `.ai/stacks/rails/STANDARDS` lists the Rails ones. The files stay in `.ai/standards/` so existing links keep working.

`_stack_id` returns `rails` when the project has a `Gemfile`, `config/application.rb`, or `bin/rails`. Otherwise it returns `unspecified`. `rorcc workflow --plan` prints that id. The router does not drop or add units because of it.

## Alternatives Considered

| Option | Pros | Cons |
|--------|------|------|
| Lists plus a printed stack id (chosen) | Selection stays the same. The split is explicit. | The markdown files are not in two directories yet. |
| Move the markdown into `.ai/stacks/` now | The tree matches the diagram. | Breaks links and can change what a plan selects. |
| Filter skills by stack id now | A non-Rails tree would skip Rails skills. | This phase forbids a second stack and a behavior change. |

## Consequences

### Positive

- A Rails app still gets the same selected units.
- The next stack can add a list without moving the core files first.

### Negative

- Two places name each standard: the file, and the list. The lists must be updated when a standard is added.

## Compliance

- Standards: [`.ai/standards/orchestration.md`](../../.ai/standards/orchestration.md)
- Stories blocked until Accepted: none

---

## Versión en español

# ADR-0010: Nombrar el stack sin cambiar lo que el router selecciona

## Estado

Accepted

## Decisión

`.ai/stacks/core/STANDARDS` lista los standards agnósticos. `.ai/stacks/rails/STANDARDS` lista los de Rails. Los archivos siguen en `.ai/standards/`.

`_stack_id` devuelve `rails` si hay `Gemfile`, `config/application.rb` o `bin/rails`. Si no, `unspecified`. `rorcc workflow --plan` imprime ese id y no cambia las unidades seleccionadas.
