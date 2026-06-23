# create-feature-spec

## Purpose

Guide collaborative authoring of a feature specification from a raw idea to an approved document ready for user stories.

**Use when:** starting a new feature, capturing scope/goals/non-goals, or writing `docs/specs/feature-*.md`.

## Inputs

- Business idea, problem statement, or stakeholder request
- Existing product context and constraints
- Template: `.ai/templates/feature-specification.md`

## Outputs

- `docs/specs/feature-[slug].md` (approved feature specification)

## Execution Steps

1. **Clarify** — Ask about users, pain points, success metrics, and non-goals.
2. **Draft goals** — Present measurable goals and explicit non-goals for approval.
3. **Outline stories** — Summarize user stories table (not full stories yet).
4. **Define acceptance criteria** — Testable criteria per story summary.
5. **Flag technical scope** — Note integrations (AWS, ERP/third-party APIs) and ADR needs.
6. **Draft document** — Fill template; show draft for review.
7. **Approve** — Obtain Product Owner sign-off before marking Approved.

## Validation Checklist

- [ ] Problem statement is clear and user-focused
- [ ] Goals are measurable
- [ ] Non-goals explicitly listed
- [ ] Acceptance criteria are testable
- [ ] Open questions tracked with owners
- [ ] Product Owner approval recorded

## Agent

`product-owner` — see `.ai/agents/product-owner.yaml`

## Workflow

`.ai/workflows/new-feature.yaml` → phase `idea`
