> Language: English | [Español](#versión-en-español)

# ADR-0007: File and shell actions restore to a git checkpoint

## Status

Accepted

## Date

2026-09-24

## Context

[ADR-0006](adr-0006-app-builder-outside-rorcc-inside.md) holds phase 2 until phase 1 is in place. Phase 1 is merged. The builder still does not apply file or shell changes. bolt.diy runs those actions in a browser container. This kit writes to the real project tree, and a failed action must leave that tree as it was before the run.

## Decision

`rorcc actions <file>` runs a local action list in the project root. Each entry is `file` or `shell`. The runner prints `pending`, `running`, then `complete` or `failed`.

Before the first action it writes a git commit object at `refs/rorcc/checkpoint`. That object holds the worktree, including untracked files. It does not move `HEAD`. On failure, or on `rorcc actions --undo`, the worktree returns to that commit and `HEAD` stays where the run started.

A path that is absolute or contains `..` is rejected and nothing runs. The action file is trusted local input. There is no WebContainer and no second snapshot store.

## Alternatives Considered

| Option | Pros | Cons |
|--------|------|------|
| Git commit object at `refs/rorcc/checkpoint` (chosen) | Undo is git. `HEAD` does not move. Untracked files are in the tree. | One ref to know about. |
| `git stash push` before the run | Familiar undo. | Hides the user's own edits for the duration of the run. |
| Copy the tree to a directory | Easy to restore. | A second snapshot store, which phase 2 forbids. |

## Consequences

### Positive

- A failed action does not leave a half-written tree.
- Success leaves the action results in place. `--undo` can still return to the checkpoint.

### Negative

- The project must already be a git repository with at least one commit.
- A shell action can do anything the user can do in that repository. The runner does not sandbox it.

## Compliance

- Standards: [`.ai/standards/git-workflow.md`](../../.ai/standards/git-workflow.md), [`.ai/standards/minimalism.md`](../../.ai/standards/minimalism.md)
- Stories blocked until Accepted: none

---

## Versión en español

# ADR-0007: Las acciones file y shell vuelven a un checkpoint de git

## Estado

Accepted

## Fecha

2026-09-24

## Decisión

`rorcc actions <archivo>` ejecuta acciones `file` y `shell` en la raíz del proyecto. Antes imprime `pending` y `running`, y después `complete` o `failed`.

Antes de la primera acción guarda un commit en `refs/rorcc/checkpoint` con el árbol, incluidos los archivos sin seguimiento. No mueve `HEAD`. Si una acción falla, o con `rorcc actions --undo`, el árbol vuelve a ese commit.

Una ruta absoluta o con `..` se rechaza y no corre nada. El archivo de acciones es entrada local de confianza. No hay WebContainer ni otro almacén de snapshots.
