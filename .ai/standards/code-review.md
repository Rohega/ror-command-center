# Code Review Standards

## Review Scope

- Correctness vs acceptance criteria
- ADR compliance
- Security (auth, input validation, secrets)
- Test adequacy
- Migration safety (if applicable)
- Performance red flags (N+1, unbounded queries)

## Severity Levels

| Level | Action |
|-------|--------|
| **BLOCKING** | Must fix before merge — security, data loss, broken migration |
| **WARNING** | Should fix — missing tests, ADR drift, performance |
| **INFO** | Optional — style, naming, suggestions |

## Reviewer Checklist

- [ ] Changes match story scope — no unrelated drive-by refactors
- [ ] Authorization present on new endpoints/actions
- [ ] Tests added/updated for changed behavior
- [ ] Migrations reversible or explicitly documented
- [ ] No secrets or credentials in diff
- [ ] ADR referenced or new ADR needed

## Turnaround

- Reviews within 1 business day for normal PRs
- Hotfix reviews prioritized

## References

- Agent: `.ai/agents/qa-engineer.yaml` (code review responsibilities)
- Skill: `review-rails-models`, `review-db-migrations`
- Standard: `.ai/standards/development.md`
