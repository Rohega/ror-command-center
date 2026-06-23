# reverse-document-legacy

## Purpose

Audit an existing, spec-less Ruby on Rails application and produce the documentation
a team needs to work safely: module docs, a system map (models/routes/jobs/integrations),
retrospective ADRs, and a prioritized risk list. This is the discovery and
reverse-documentation capability behind `.ai/workflows/legacy-onboarding.yaml`.

**Use when:** onboarding a legacy or undocumented codebase, or starting `.ai/workflows/legacy-onboarding.yaml`.

## Inputs

- Read access to the target Rails application (path scope optional, e.g. one engine/module)
- Argument: `map` | `module` | `risks` | `adr`
  - `map` — whole-app inventory and system map
  - `module <name/path>` — deep audit of one module/domain
  - `risks` — risk register and hotspot report
  - `adr` — reconstruct retrospective ADRs from as-built code
- Optional: existing `docs/`, `db/schema.rb`, `config/routes.rb`, `Gemfile.lock`

## Outputs

- System map: `docs/modules/_system-map.md` (models, routes, jobs, integrations, gems/Rails version)
- Module docs: `docs/modules/<name>.md` (from `.ai/templates/legacy-module-audit.md`)
- Retrospective ADRs: `docs/architecture/adr-NNNN-*.md` (from `.ai/templates/retrospective-adr.md`)
- Risk/hotspot summary feeding `.ai/templates/modernization-plan.md`

## Execution Steps

1. **Confirm scope** — whole app or a module/path? Confirm read-only, no behavior changes.
2. **Detect stack** — Rails version, Ruby version, DB, key gems (`Gemfile.lock`),
   background processor (Sidekiq/ActiveJob), auth (Devise), admin (ActiveAdmin).
3. **Inventory** — enumerate:
   - Models + associations (from `app/models`, `db/schema.rb`)
   - Routes → controllers#actions (`config/routes.rb`), auth per route
   - Background jobs + queues + triggers; idempotency
   - Service objects/POROs and their responsibilities
   - External integrations (HTTP clients, webhooks, secrets location)
4. **Find hotspots** — large/churny files, missing tests, TODO/FIXME/HACK,
   end-of-life gems and Rails version risk. Reuse `tech-debt-analysis` where useful.
5. **Identify seams** — note where behavior can be changed safely
   (per `.ai/standards/legacy-rails.md`).
6. **Reconstruct decisions** — for non-obvious as-built choices, draft retrospective
   ADRs and mark confidence (High/Medium/Low).
7. **Draft docs** — fill `legacy-module-audit.md` per module and the system map; keep
   examples runnable or marked illustrative.
8. **Summarize risks** — prioritized impact × effort list, ready for a modernization plan.
9. **Approve** — show drafts and proposed file paths before writing (collaboration protocol).

## Validation Checklist

- [ ] Stack and versions (Ruby, Rails, DB, key gems) recorded
- [ ] Every public route maps to a controller#action with auth noted
- [ ] Jobs documented with queue, trigger, and idempotency
- [ ] External integrations list failure handling and secret location (no secret values)
- [ ] Each retrospective ADR states confidence and evidence
- [ ] Risks scored by impact × effort
- [ ] No application code modified; output is documentation only
- [ ] Audit date and Rails version stamped on each doc

## Agent

`documentation-writer` (reverse-documentation); `rails-architect` (architecture/ADRs);
`code-reviewer` via `tech-debt-analysis` (hotspots)
