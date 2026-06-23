# create-architecture-plan

## Purpose

Produce architecture decisions and technical design for a feature before implementation begins.

**Use when:** a feature needs data modeling, integration design, or significant technical decisions captured as an ADR.

## Inputs

- User stories and feature specification
- Existing ADRs in `docs/architecture/`
- Standards: `.ai/standards/development.md`, `.ai/standards/api-design.md`
- Template: `.ai/templates/technical-design-document.md`, `.ai/templates/architecture-decision-record.md`

## Outputs

- `docs/architecture/adr-NNNN-[slug].md` (per significant decision)
- `docs/design/[feature-slug].md` (technical design when complex)

## Execution Steps

1. **Load context** — Read stories, existing ADRs, and relevant code.
2. **Identify decisions** — List technical choices requiring ADRs.
3. **Present options** — 2–3 alternatives with pros/cons per decision.
4. **Draft ADRs** — Status Proposed; user accepts → Accepted.
5. **Draft technical design** — Components, data model, APIs, security.
6. **Review dependencies** — AWS and external system integration points.
7. **Approve** — Block implementation until ADRs Accepted for governing decisions.

## Validation Checklist

- [ ] Every significant decision has ADR or explicit waiver
- [ ] ADRs include alternatives and consequences
- [ ] Technical design links to ADRs
- [ ] Security and data model addressed
- [ ] Stories unblocked only when ADRs Accepted

## Agent

`rails-architect`

## Workflow

`.ai/workflows/new-feature.yaml` → phase `architecture`
