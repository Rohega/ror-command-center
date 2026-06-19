# Legacy Rails Standards

> How to safely understand, document, and intervene in inherited or
> spec-less Ruby on Rails applications. Pairs with `.ai/standards/testing.md`,
> `.ai/standards/development.md`, and `.ai/standards/security.md`.

"Legacy" here means a production Rails app you did not design: missing or stale
specs, thin test coverage, outdated dependencies, and tribal knowledge. The goal
is to make change **safe and reversible** before making it fast.

## Principles

1. **Understand before you touch.** Reverse-document the system (models, routes,
   jobs, integrations) before changing behavior. See skill `reverse-document-legacy`.
2. **Characterize, then change.** Add characterization tests that pin current
   behavior — including bugs — before refactoring.
3. **Small, reversible steps.** Prefer many low-risk PRs over a big-bang rewrite.
4. **Strangler fig over rewrite.** Grow new code around the old, redirect traffic
   incrementally, and delete the legacy path only once it is unused.
5. **Leave it better.** Apply the boy-scout rule to files you touch; do not
   refactor unrelated code in the same PR.

## Characterization Testing

Characterization tests describe what the system *does today*, not what it *should*
do. They are the safety net for refactoring.

- Write tests around the **seam** you intend to change (a class, endpoint, or job).
- Capture real outputs (golden master / approval testing) when logic is too tangled
  to assert piece by piece; snapshot the output and diff on change.
- Pin **observable behavior**, including known quirks. File a tech-debt entry for
  bugs you intentionally preserve.
- Add tests at the **highest stable level** first (request/system specs), then push
  coverage down to units as you extract logic.

| Layer | First move on legacy code |
|-------|---------------------------|
| Untestable controller | Request spec around the route, then extract a service |
| Fat model | Characterize public methods, then extract POROs/services |
| Background job | Spec success + retryable failure, then refactor `perform` |
| External integration | Record/replay (e.g. VCR) to pin the contract |

## Finding Seams

A *seam* is a place where you can alter behavior without editing the code in place.

- Dependency injection: pass collaborators in instead of hard-coding `Foo.new`.
- Extract method/class to isolate the risky logic behind a small interface.
- Wrap third-party calls in an adapter so they can be stubbed and later swapped.
- Introduce a feature flag to toggle old vs new code paths at runtime.

## Strangler Fig Pattern

Incrementally replace a legacy subsystem instead of rewriting it.

1. **Identify the boundary** — a module, endpoint group, or domain concept.
2. **Insert a facade** — route calls through a thin interface you control.
3. **Build the new path** behind a flag; keep the old path as default.
4. **Shift traffic** gradually (per-tenant, percentage, or per-endpoint), comparing
   outputs where feasible.
5. **Retire** the legacy path and delete dead code once traffic is fully migrated.

Always keep a documented rollback: a flag flip or revert that restores the old path.

## Technical Debt

- Record findings in `docs/tech-debt/register.md` (skill `tech-debt-analysis`),
  scored by impact × effort.
- Tie critical debt to concrete production risk (data loss, security, downtime).
- Track Rails/gem version risk and end-of-life dependencies as first-class debt.
- Do not silently fix unrelated debt mid-feature — log it and schedule it.

## Rails Version Upgrades

Treat upgrades as an incremental, test-guarded project — never a single jump.

### Prerequisites

- A green build on the **current** version with meaningful coverage on critical paths.
- Pinned dependencies (`Gemfile.lock` committed) and a working CI pipeline.
- An inventory of gems that constrain the Rails version (`bundle outdated`).

### Step-by-step

1. **Upgrade one minor at a time** (e.g. 5.2 → 6.0 → 6.1 → 7.0), never skipping majors.
2. **Read the official upgrade guide** for each target and run
   `rails app:update`, reviewing every `config/` diff by hand.
3. **Dual-boot when useful** — use the `next_rails`/`bootboot` approach (or a branch)
   to run the suite against both versions during the transition.
4. **Resolve deprecations first.** Run on the current version with deprecation
   warnings as errors, fix them, then bump.
5. **Framework defaults** — adopt `new_framework_defaults_*.rb` one flag at a time,
   each behind its own commit and test run.
6. **Upgrade gems alongside Rails**; replace abandoned gems before they block the bump.
7. **Verify in staging** with production-like data before release.

### Rollback

- Each upgrade ships as its own deployable release with a clean revert path.
- Keep the prior release artifact available; document the flip-back in a runbook
  (`docs/runbooks/`). Reversible migrations only — see `.ai/standards/postgresql.md`.

## Anti-Patterns

- Big-bang rewrite with no incremental delivery or rollback.
- Refactoring without characterization tests ("trust me" changes).
- Upgrading multiple Rails majors in one step.
- Mixing behavior changes and refactors in the same PR.
- Touching code outside the documented seam for a given change.

## References

- Agent: `.ai/agents/documentation-writer.yaml`
- Skill: `reverse-document-legacy`, `tech-debt-analysis`, `document-module`
- Workflow: `.ai/workflows/legacy-onboarding.yaml`
- Templates: `.ai/templates/legacy-module-audit.md`, `.ai/templates/modernization-plan.md`, `.ai/templates/retrospective-adr.md`
- Standards: `.ai/standards/testing.md`, `.ai/standards/development.md`, `.ai/standards/security.md`, `.ai/standards/postgresql.md`
