---
name: document-module
description: "Create or update technical documentation for a code module, service, or integration, aimed at developers. Use when documenting how a module works internally, after building or changing a module, or writing docs/modules/*."
---
# document-module

## Purpose

Create or update technical documentation for a code module, service, or integration.

**Use when:** documenting how a module works internally, after building or changing a module, or writing `docs/modules/*`.

## Inputs

- Module path(s) in `app/`
- Related ADRs and feature specs
- Standard: `.ai/standards/documentation.md`

## Outputs

- `docs/modules/[module-name].md` or updated API/runbook docs

## Execution Steps

1. **Read code** — Models, services, jobs, integration clients.
2. **Identify audience** — Developer onboarding vs operations runbook.
3. **Outline** — Purpose, dependencies, public interface, configuration.
4. **Draft** — Examples, error handling, related ADRs.
5. **Cross-check** — Docs match current implementation.
6. **Approve** — Show draft before writing.
7. **Link** — Add to docs index or README if new area.

## Validation Checklist

- [ ] Purpose and boundaries clearly stated
- [ ] Configuration and ENV documented
- [ ] Error cases and retry behavior described
- [ ] Links to ADRs for architectural decisions
- [ ] Examples accurate against current code

## Agent

`documentation-writer`
