> Language: English | [Español](#versión-en-español)

# ADR-0009: Preview refresh and restart are commands, not the Definition of Done

## Status

Accepted

## Date

2026-09-24

## Context

[ADR-0006](adr-0006-app-builder-outside-rorcc-inside.md) holds phase 4 until the security pass exists. Phase 3 is merged. A Rails app from `rorcc init --docker` is already served by `docker compose` on port 3000. Dyad asks the model to emit a refresh or restart tag instead of telling the person to type a shell command. A green preview is not a finished change.

## Decision

`rorcc preview` prints the URL of the app `docker compose` already serves. `rorcc preview refresh` requests that URL. `rorcc preview restart` restarts the `web` service. Neither command tells the person to type a shell command. Neither command closes the proportional Definition of Done.

## Alternatives Considered

| Option | Pros | Cons |
|--------|------|------|
| Two commands over the existing compose file (chosen) | No new server. Refresh and restart are actions, not instructions. | Requires the compose file from `rorcc init --docker`. |
| An iframe inside a new UI | Matches Dyad's screen. | A product shell, which is phase 7. |
| Treat a live URL as done | Fast to show. | Skips tests and the security pass. |

## Consequences

### Positive

- Refresh and restart do not depend on the person knowing Docker.
- A down preview is a status, not a passed review.

### Negative

- `restart` needs a working Docker daemon. The command reports that Docker is not available instead of printing a command to copy.

## Compliance

- Standards: [`.ai/standards/orchestration.md`](../../.ai/standards/orchestration.md)
- Stories blocked until Accepted: none

---

## Versión en español

# ADR-0009: Refresh y restart son comandos, no el Definition of Done

## Estado

Accepted

## Decisión

`rorcc preview` muestra la URL que ya sirve `docker compose`. `refresh` pide esa URL. `restart` reinicia el servicio `web`. Ninguno pide teclear un comando de shell, y ninguno cierra el Definition of Done.
