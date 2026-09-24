> Language: English | [Español](#versión-en-español)

# ADR-0008: Security findings cite only files the pass opened

## Status

Accepted

## Date

2026-09-24

## Context

[ADR-0006](adr-0006-app-builder-outside-rorcc-inside.md) holds phase 3 until the action runner exists. Phase 2 is merged. The testing phase already runs `security-audit` with `security-reviewer` when size or signals require it. That skill is a model turn. The close of the builder needs a written finding with a title, a level, a risk, and files, and it must not name a file it did not open.

## Decision

`rorcc security` runs after the workflow when the builder accepts, and it can be run on its own. It runs only when the proportional Definition of Done already requires a security review: size `L` or `XL`, or the signal `auth_changed`. Otherwise it prints `security pass skipped` and writes nothing.

When it runs, it opens the changed source files, or the paths given with `--paths`. Each finding is four lines: `title`, `level`, `risk`, `files`. The `files` line is a path this pass opened. The report is `docs/security/findings-<utc>.md`. No new model and no new specialist.

## Alternatives Considered

| Option | Pros | Cons |
|--------|------|------|
| A shell pass with the existing DoD gate (chosen) | Same trigger as the review that already exists. Findings are checkable without a model. | It only sees patterns it can name in shell. The model skill still runs inside the workflow. |
| Call `security-reviewer` again at the close | Fuller prose. | A second model turn, and no guarantee the cited files were opened. |
| Always write a report | Visible on every run. | Size S copy changes would pay for a review the DoD skips. |

## Consequences

### Positive

- A size S change with no auth signal does not gain a security file.
- A finding cannot name a file the pass did not read.

### Negative

- The shell pass is not the whole `security-audit` skill. Injection and authorization gaps that are not in the two patterns still belong to the model skill inside the workflow.

## Compliance

- Standards: [`.ai/standards/security.md`](../../.ai/standards/security.md), [`.ai/standards/orchestration.md`](../../.ai/standards/orchestration.md)
- Stories blocked until Accepted: none

---

## Versión en español

# ADR-0008: Los hallazgos citan solo archivos que el pase abrió

## Estado

Accepted

## Decisión

`rorcc security` corre al cierre del builder, y también solo. Corre si el tamaño es `L` o `XL`, o si la señal es `auth_changed`. Si no, imprime `security pass skipped` y no escribe nada.

Cuando corre, abre los archivos cambiados o los de `--paths`. Cada hallazgo tiene `title`, `level`, `risk` y `files`. `files` es una ruta que este pase abrió. El informe queda en `docs/security/findings-<utc>.md`. No hay un modelo nuevo ni un especialista nuevo.
