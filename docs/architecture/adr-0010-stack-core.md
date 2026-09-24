> Language: English | [Español](#versión-en-español)

# ADR-0010: Name the stack without changing what the router selects

## Status

Accepted

## Date

2026-09-24

## Context

[ADR-0006](adr-0006-app-builder-outside-rorcc-inside.md) phase 5 names a stack without changing what `new-feature --plan` selects. Standards that apply to any stack live in the same directory as Rails-only ones. Cursor rules, skills, agents, and docs already link `.ai/standards/<file>.md`. `install.sh` copies that tree as-is.

## Decision

The cut is the list, not a directory. `.ai/stacks/core/STANDARDS` names the stack-agnostic files. `.ai/stacks/rails/STANDARDS` names the Rails ones. The markdown stays in `.ai/standards/`. Moving it would break `@` includes in `.cursor/rules/`, the links those rules and `install.sh` copy into a project, and the path router’s current selection.

`.ai/standards/rails.md` is the Rails identity. `_stack_id` returns `rails` when the project has a `Gemfile`, `config/application.rb`, or `bin/rails`. Those markers win over `next.config.*`. `new-feature` is the Rails workflow. `rorcc workflow --plan` prints the id and does not drop or add units because of it. In this kit the id is `unspecified` and `new-feature --plan` still selects 12 units.

## Alternatives Considered

| Option | Pros | Cons |
|--------|------|------|
| Lists in `.ai/stacks/`, markdown left in `.ai/standards/` (chosen) | The stack is named and usable. Links, Cursor rules, and `install.sh` keep working. Selection stays the same. | Two places name each standard: the file, and the list. |
| Move the markdown into `.ai/stacks/` | The tree matches a diagram. | Breaks Cursor `@` rules, copied links, and can change what a plan selects. |
| Filter skills by stack id | A non-Rails tree would skip Rails skills. | Changes `new-feature --plan`. This decision forbids that. |

## Consequences

### Positive

- A Rails app is identifiable (`rails` from the three markers) and usable (`new-feature`) without a new selection.
- A later stack adds a list. It does not move the files already linked from `.ai/standards/`.

### Negative

- Adding a standard means editing both the file and the list. The list is the membership check.

## Compliance

- Standards: [`.ai/standards/orchestration.md`](../../.ai/standards/orchestration.md)
- Stories blocked until Accepted: none

---

## Versión en español

# ADR-0010: Nombrar el stack sin cambiar lo que el router selecciona

## Estado

Accepted

## Decisión

El corte es la lista, no el directorio. `.ai/stacks/core/STANDARDS` y `.ai/stacks/rails/STANDARDS` nombran los archivos. El markdown sigue en `.ai/standards/` porque moverlo rompe las reglas de Cursor (`@`), los enlaces que `install.sh` copia y la selección actual del router.

`.ai/standards/rails.md` identifica el stack. El id `rails` sale de `Gemfile`, `config/application.rb` o `bin/rails`, y gana sobre `next.config.*`. El workflow es `new-feature`. `--plan` imprime el id y no cambia las unidades. En este kit el id es `unspecified` y `new-feature --plan` sigue en 12.
