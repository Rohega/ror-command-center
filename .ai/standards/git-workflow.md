# Git Workflow Standards

## Branching

- `main` — always deployable, protected
- `feature/<ticket>-<slug>` — new work
- `hotfix/<ticket>-<slug>` — production fixes
- `release/<version>` — optional release stabilization

## Commits

- Conventional Commits: `feat:`, `fix:`, `chore:`, `docs:`, `test:`, `refactor:`
- Reference ticket/story ID in body: `Story: WAR-123`
- Atomic commits — one logical change per commit when possible

## Pull Requests

- Description: what, why, how to test
- Link user story or ADR
- Require code review before merge
- CI green before merge

## Releases

- Semantic versioning: `MAJOR.MINOR.PATCH`
- Git tag on every production release: `v1.2.3`
- Changelog updated per release

## Protected Operations

- No force push to `main`
- No direct commits to `main` (PR only)

## References

- Standard: `.ai/standards/code-review.md`
- Agent: `.ai/agents/aws-devops-engineer.yaml` (release coordination)
