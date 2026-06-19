# Testing Standards

> Testing principles for Ruby on Rails (RSpec, factories, system specs). Backend
> conventions live in `.ai/standards/development.md`.

## Pyramid

1. **Unit** — pure logic, models, services, parsers (fast, isolated)
2. **Integration** — API endpoints, persistence, background work against a test DB
3. **System/E2E** — end-to-end critical user journeys (few, stable)

## Conventions

- Test files mirror the structure of the code under test
- Describe/group blocks match the class/method/handler under test
- One logical assertion per test when practical
- Prefer factories/builders over static fixtures for dynamic data
- Choose the concrete framework and helpers from the stack standard
  (e.g. Rails: RSpec + FactoryBot + Capybara)

## Coverage Expectations

| Layer | Minimum |
|-------|---------|
| Core logic / services | Critical paths covered |
| API endpoints | Happy path + auth failure + validation errors |
| Async / jobs | Success + retryable failure |
| Migrations / schema | Rollback or forward-compat tested |

## CI

- Full suite on every PR to main
- Fail build on test failure — no skipped/pending tests without a ticket reference
- Dependency and security scans run in the same pipeline

## Evidence

- QA test plan maps stories to automated vs manual tests
- Bug fixes include a regression test when feasible

## References

- Agent: `.ai/agents/qa-engineer.yaml`
- Skills: `qa-plan`, `release-checklist`
