# create-user-stories

## Purpose

Break an approved feature specification into implementable user stories with acceptance criteria and traceability.

**Use when:** turning a spec into a backlog, writing stories, or defining acceptance criteria.

## Inputs

- Approved feature spec (`docs/specs/feature-*.md`)
- Sprint capacity and priorities from Product Owner

## Outputs

- `docs/stories/[feature-slug]/US-NNN.md` per story

## Execution Steps

1. **Load spec** — Read approved feature specification.
2. **Decompose** — Split into INVEST-compliant stories (Independent, Negotiable, Valuable, Estimable, Small, Testable).
3. **Write stories** — Format: As a [role], I want [action], so that [benefit].
4. **Acceptance criteria** — Given/When/Then or checklist per story.
5. **Link** — Reference feature spec ID and future ADR placeholder if needed.
6. **Prioritize** — Order by dependency and value; confirm with Product Owner.
7. **Approve** — Show full set before writing files.

## Validation Checklist

- [ ] Each story has unique ID and acceptance criteria
- [ ] Stories trace to feature spec goals
- [ ] No story larger than one sprint without split plan
- [ ] Dependencies between stories documented
- [ ] Product Owner approved priority order

## Agent

`product-owner`

## Workflow

`.ai/workflows/new-feature.yaml` → phase `user-stories`
