---
name: capistrano-review
description: "Review Capistrano deployment configuration for safety, rollback capability, and hook correctness. Use when auditing deploy.rb, Capistrano stages/tasks, or before a Capistrano-based release."
paths:
  - "config/deploy.rb"
  - "config/deploy/**"
  - "lib/capistrano/**"
---
# capistrano-review

## Purpose

Review Capistrano deployment configuration for safety, rollback capability, and hook correctness.

**Use when:** auditing `deploy.rb`, Capistrano stages/tasks, or before a Capistrano-based release.

## Inputs

- `Capfile`, `config/deploy.rb`, `config/deploy/*.rb`
- Linked files/dirs, migration strategy, Puma/nginx integration

## Outputs

- Review report with deployment risk assessment

## Execution Steps

1. **Stages** — staging/production server definitions and branch mapping.
2. **Linked files** — `master.key`, database.yml, shared paths correct.
3. **Hooks** — `before_migrate`, `after_publish`, asset precompile order.
4. **Migrations** — `deploy:migrate` timing and failure handling.
5. **Rollback** — `deploy:rollback` tested path documented.
6. **Secrets** — No credentials in repo; linked_files list complete.
7. **Report** — BLOCKING for migration or secret risks.

## Validation Checklist

- [ ] Production deploy requires explicit stage confirmation
- [ ] Migrations run in documented order with backup prerequisite
- [ ] `keep_releases` sufficient for rollback
- [ ] Asset pipeline and Sidekiq restart hooks correct
- [ ] No destructive tasks without guard

## Agent

`release-manager`

## Workflow

`.ai/workflows/aws-deployment.yaml`, `.ai/workflows/new-feature.yaml` → `release`
