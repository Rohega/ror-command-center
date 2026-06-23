# aws-deploy-plan

## Purpose

Create a deployment plan for AWS-hosted Rails applications including infrastructure changes and validation steps.

**Use when:** planning or documenting an AWS deploy, preparing a staging/production release, or producing a deployment plan.

## Inputs

- Release scope, migrations, and config changes
- Current IaC and Capistrano config
- Template: `.ai/templates/deployment-plan.md`
- Standard: `.ai/standards/aws-infrastructure.md`

## Outputs

- `docs/deployments/plan-[version]-[date].md`

## Execution Steps

1. **Inventory changes** — Code, migrations, ENV, IaC deltas.
2. **Environment matrix** — Staging vs production parity check.
3. **IAM & secrets** — New permissions or parameter store updates.
4. **Deployment sequence** — Ordered steps with commands.
5. **Validation** — Health checks and smoke test scope.
6. **Rollback** — Triggers, commands, RTO.
7. **Approve** — Review with Release Manager before execution.

## Validation Checklist

- [ ] Staging deploy step precedes production
- [ ] Database backup step included
- [ ] Rollback strategy documented
- [ ] IAM changes follow least privilege
- [ ] Contacts and maintenance window listed

## Agent

`aws-devops-engineer`

## Workflow

`.ai/workflows/aws-deployment.yaml`
