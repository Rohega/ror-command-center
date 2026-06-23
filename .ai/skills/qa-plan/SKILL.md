# qa-plan

## Purpose

Generate a structured QA test plan mapping user stories to automated and manual test coverage.

**Use when:** planning QA for a feature or release, defining test cases, or before QA sign-off.

## Inputs

- User stories in scope (sprint or feature)
- Feature spec and acceptance criteria
- Template: `.ai/templates/qa-test-plan.md`
- Standard: `.ai/standards/testing.md`

## Outputs

- `docs/qa/plan-[scope]-[date].md`

## Execution Steps

1. **Scope** — List stories from sprint folder or feature slug.
2. **Classify** — Unit / Integration / E2E / Manual per story.
3. **Map specs** — Existing or required `spec/` files per story.
4. **Manual cases** — Steps and expected results for non-automatable criteria.
5. **Smoke scope** — Critical paths for release gate.
6. **Sign-off criteria** — Blocking vs advisory tests.
7. **Approve** — QA Engineer and Product Owner acknowledge plan.

## Validation Checklist

- [ ] Every story has at least one test method defined
- [ ] Smoke test covers login and critical business paths
- [ ] Evidence location specified
- [ ] S1/S2 block release if open
- [ ] Plan created before implementation completes (ideal)

## Agent

`qa-engineer`

## Workflow

`.ai/workflows/new-feature.yaml` → phase `qa`
