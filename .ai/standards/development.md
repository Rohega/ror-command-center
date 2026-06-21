# Rails Development Standards

> Core Ruby on Rails development standard. Cross-cutting rules live alongside in `.ai/standards/` (security, testing, api-design, git-workflow, …).

## Conventions

- Follow Rails conventions over custom abstractions
- Use standard MVC; extract to service objects when a controller action exceeds ~15 lines or logic is reused
- Prefer `app/services/`, `app/jobs/`, `app/policies/` over lib/ unless truly framework-agnostic
- Use strong parameters in all controllers
- Authorization via Pundit or equivalent — every mutating action checked

## Models

- Validations in models; complex cross-model rules in service objects
- Use `enum` with prefix/suffix for status fields
- Scopes for reusable query fragments; avoid class methods that hide side effects
- Callbacks sparingly — prefer explicit service calls for multi-step workflows

## Controllers & APIs

- Thin controllers: load, authorize, delegate, respond
- JSON APIs use consistent serializer layer (Blueprinter, Alba, or jbuilder per ADR)
- Version APIs in URL path when breaking changes expected (`/api/v1/`)

## Background Jobs

- Idempotent jobs with explicit retry and discard policies
- Pass IDs, not ActiveRecord objects, to jobs
- Long-running work never blocks HTTP requests

## Configuration

- Environment-specific config in credentials or ENV — never hardcode secrets
- Feature flags for risky rollouts when appropriate

## Tooling

- New apps: bootstrap the test stack first — see `.ai/standards/project-bootstrap.md`
- Tests: RSpec (see `.ai/standards/testing.md` for the agnostic principles)
- Lint: RuboCop — no new offenses in changed files
- Dependencies: Bundler + `bundle audit`

## References

- Agent: `.ai/agents/backend-rails-developer.yaml`
- Data layer: `.ai/standards/postgresql.md`, `.ai/standards/mysql.md`
- Skills: `review-rails-models`, `create-api-endpoints`
