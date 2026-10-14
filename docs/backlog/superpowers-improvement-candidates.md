# Superpowers comparison — improvement candidates

Status: **BACKLOG / NOT IMPLEMENTED**. Reference: https://github.com/obra/superpowers

These are hypotheses, not confirmed gaps. Audit current `main` before planning any implementation.

## Candidates
1. **Evidence-based completion (high priority):** require actual test/check output before reporting success, scaled to task risk.
2. **Two-stage review (high priority):** specification compliance followed by code quality/security/maintainability for significant tasks.
3. **Systematic debugging (high priority):** reproduce, isolate root cause, test hypothesis, and verify regressions before patching.
4. **Risk-based TDD (medium priority):** RED-GREEN-REFACTOR for critical logic, without burdening trivial changes.
5. **Worktree isolation (evaluate):** assess existing isolation for parallel tasks; add only if missing and useful.
6. **Token-efficient execution (evaluate):** compare costs of agents/reviews/iterations; avoid unnecessary cycles.

## Before implementation
- Inspect Task Router, Classifier, orchestrator, skills, testing, and Cursor/Claude/Codex flows on `main`.
- For each candidate mark **existing / partial / absent / unnecessary**, with file-path evidence.
- Compare the exact Superpowers mechanism and estimate benefits, token overhead, complexity, and risk.
- Prioritize small measurable phases and acceptance tests; preserve multi-agent compatibility.
- Do not add agents, documentation, or process steps without a concrete need.

No code changes, runtime executions, or merges are authorized by this backlog entry.
