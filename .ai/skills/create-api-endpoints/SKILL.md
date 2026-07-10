---
name: create-api-endpoints
description: "Implement REST API endpoints per user story, ADR, and API design standards. Use when building or extending a Rails API, adding controller actions or serializers, or wiring routes for a new endpoint."
paths:
  - "app/controllers/**"
  - "config/routes.rb"
  - "app/serializers/**"
---
# create-api-endpoints

## Purpose

Implement REST API endpoints per user story, ADR, and API design standards.

**Use when:** building or extending a Rails API, adding controller actions or serializers, or wiring routes for a new endpoint.

## Inputs

- User story with API acceptance criteria
- Governing ADR and `.ai/standards/api-design.md`
- Routes, serializers, policies in codebase

## Outputs

- Controller, routes, serializer, policy, and RSpec request specs

## Execution Steps

1. **Load story & ADR** — Confirm scope and response shape.
2. **Design contract** — Method, path, params, response JSON, error codes.
3. **Propose implementation** — Controller action, service if needed, policy rules.
4. **Approve** — Show plan before writing.
5. **Implement** — Strong params, authorization, validation, serializer.
6. **Test** — Request specs: success, 401, 403, 422, 404 as applicable.
7. **Document** — Update API docs if external-facing.

## Validation Checklist

- [ ] All acceptance criteria covered by specs
- [ ] Authorization on every action
- [ ] Errors follow API standard envelope
- [ ] No N+1 in index/show actions
- [ ] ADR compliance verified

## Agent

`backend-rails-developer`

## Workflow

`.ai/workflows/new-feature.yaml` → phase `implementation`
