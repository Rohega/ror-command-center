# release-checklist

## Purpose

Generate and execute a pre-release validation checklist before production deployment.

**Use when:** preparing a release, verifying readiness, or gating a production deploy.

## Inputs

- Release version and scope
- QA sign-off, migration list, changelog
- Template: `.ai/templates/release-checklist.md`

## Outputs

- Completed `docs/releases/checklist-v[X.Y.Z].md`

## Execution Steps

1. **Load context** — Version, stories, migrations, deploy plan.
2. **Codebase scan** — TODO/FIXME counts, CI status on release branch.
3. **Gate checks** — QA, security audit, DBA migration review.
4. **Generate checklist** — From template with project-specific items.
5. **Execute** — Mark items complete during release process.
6. **Post-release** — Smoke test, monitoring, git tag.
7. **Archive** — Store completed checklist with release record.

## Validation Checklist

- [ ] All pre-release items complete or waived with approver
- [ ] Staging verified before production
- [ ] Git tag matches checklist version
- [ ] Rollback path confirmed
- [ ] Post-release smoke test passed

## Agent

`release-manager`

## Workflow

`.ai/workflows/new-feature.yaml` → phase `release`
