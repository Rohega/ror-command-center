> Language: English | [Español](#versión-en-español)

# ADR-0012: The product shell stays outside this repository

## Status

Accepted

## Date

2026-09-24

## Context

[ADR-0006](adr-0006-app-builder-outside-rorcc-inside.md) holds phase 7 as a desktop or web shell that calls `rorcc`. The done line is a separate repository that does not vendor this tree. Building that shell here would make this kit the product UI.

## Decision

This repository does not gain an Electron app, a web container, or a copy of Dyad or bolt.diy. The shell, when it exists, is another repo. It may call only these commands:

- `rorcc builder`
- `rorcc workflow`
- `rorcc actions`
- `rorcc security`
- `rorcc preview`

It does not import `.ai/` by copying it into the shell. It runs against a project that already has `.ai/`.

## Alternatives Considered

| Option | Pros | Cons |
|--------|------|------|
| A command contract and no shell in this repo (chosen) | Matches the done line of phase 7. The kit stays a kit. | There is no clickable UI yet. |
| Embed Dyad or bolt.diy | A screen exists today. | Vendors another tree and drops Rails. |

## Consequences

### Positive

- Phases 1–6 stay callable from any future shell without a rewrite.
- This repo does not grow a second application.

### Negative

- A person still uses the terminal. The visual shell is a later repository, not a missing file in this one.

## Compliance

- Standards: [`.ai/standards/minimalism.md`](../../.ai/standards/minimalism.md)
- Stories blocked until Accepted: none

---

## Versión en español

# ADR-0012: El shell de producto queda fuera de este repositorio

## Estado

Accepted

## Decisión

Este repositorio no incluye la app de escritorio ni la web. El shell, si se construye, vive en otro repo y solo llama a `rorcc builder`, `workflow`, `actions`, `security` y `preview`. No copia `.ai/` dentro del shell.
