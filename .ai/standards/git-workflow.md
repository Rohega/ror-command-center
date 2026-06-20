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

## Enforcement

These rules are enforced, not just documented:

- **GitHub branch protection** on `main`: requires a PR and a green CI check
  (`Shell lint + smoke tests`); blocks force-push and deletion.
- **Local pre-commit hook** (`.githooks/pre-commit`): blocks commits on
  `main`/`master`/`develop`. Enable once per clone:
  `git config core.hooksPath .githooks`
- **Claude Code push hook** (`.claude/hooks/validate-push.sh`): blocks direct
  pushes to protected branches during agent sessions.
- Emergency overrides (discouraged): `RORCC_ALLOW_PROTECTED_COMMIT=1` (commit),
  `RORCC_ALLOW_PROTECTED_PUSH=1` (push).

## References

- Standard: `.ai/standards/code-review.md`
- Agent: `.ai/agents/aws-devops-engineer.yaml` (release coordination)
