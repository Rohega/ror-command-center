# review-rails-models

## Purpose

Review ActiveRecord models for Rails conventions, validations, associations, security, and performance.

## Inputs

- Model file path(s) under `app/models/`
- Governing ADR and user story (if applicable)
- Standard: `.ai/standards/development.md`

## Outputs

- Review report with BLOCKING / WARNING / INFO findings

## Execution Steps

1. **Read models** — Full file and related models/associations.
2. **ADR check** — Verify alignment with governing ADR.
3. **Associations** — Correct `dependent`, inverse, through associations.
4. **Validations** — Presence, format, uniqueness scoped correctly.
5. **Callbacks** — Flag risky callbacks; prefer services for side effects.
6. **Scopes & queries** — N+1 risks, unbounded `all`, missing indexes hint.
7. **Security** — Mass assignment, sensitive attributes not exposed in serializers.
8. **Report** — Classify findings; recommend approve or changes.

## Validation Checklist

- [ ] All public associations documented or self-evident
- [ ] No business logic that belongs in services
- [ ] Validations match story acceptance criteria
- [ ] No BLOCKING security or data integrity issues open
- [ ] Findings reference standards or ADRs

## Agent

`code-reviewer`
