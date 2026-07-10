# RoR Command Center — Agent Entry Point

Production-grade Ruby on Rails AI engineering team. **Canonical definitions live in `.ai/`** — this file is the entry point that binds them for every agent session (Cursor, Codex, and any AGENTS.md-aware tool).

Do not duplicate content here; reference the source of truth.

## Router — do this on every task

`.ai/` is the source of truth and works as a team. Before planning or coding,
**read the relevant standards in `.ai/standards/`**. The core always applies:
`collaboration` · `minimalism` · `development` · `project-bootstrap` · `testing` ·
`security` · `git-workflow` · `code-review` · `documentation`. Then add the
domain standard for the area you touch:

- Frontend/UI → `frontend` · `hotwire` · `ux-accessibility`
- API → `api-design` · Data → `postgresql` / `mysql` · Async → `sidekiq-activejob`
- Auth/Admin → `devise-auth` / `activeadmin` · Infra → `aws-infrastructure` / `kamal-docker`
- Legacy → `legacy-rails`

Full navigable index: `.ai/README.md`. Cursor loads this automatically via
`.cursor/rules/ai-index.mdc`; other tools load this file (`AGENTS.md`).

## Always apply

- **Standards** in `.ai/standards/` govern every change. Minimalism (`.ai/standards/minimalism.md`) and the project structure are non-negotiable defaults.
- **Engineering gates / Definition of Done** (`.cursor/rules/workflow-gates.mdc`): no feature is complete without RSpec tests, review, QA sign-off, and documentation.
- **Collaboration protocol** (`.ai/standards/collaboration.md`): Question → Options → Decision → Draft → Approval. Ask before writing files; no commits without explicit instruction.
- **Git workflow** (`.ai/standards/git-workflow.md`): work on `feature/<ticket>-<slug>` branches, Conventional Commits, never commit directly to `main`.

## Definition of Done (MUST)

For any implementation work you **MUST**:

- Produce a plan that explicitly lists **tests, review, QA, and documentation** as
  separate steps — never fold them into "implementation" or defer them.
- Write **RSpec** tests covering the critical paths before considering work done.
- Run **review** (`ponytail-review`, `review-rails-models`/`review-db-migrations`)
  and **QA** (`qa-plan`) with no BLOCKING findings.
- Add **documentation** (`document-module`) for new or changed modules.

When creating a Rails app **from scratch**, the first step is the test stack:
follow `.ai/standards/project-bootstrap.md` (RSpec + FactoryBot + SimpleCov +
generators) **before** writing application code. Do not skip these because no
`spec/`/`app/` files exist yet — the gates in `.cursor/rules/workflow-gates.mdc`
apply regardless.

## Use the specialists (subagents)

When a task matches a specialist, **delegate** to that subagent (Cursor Task /
`/<id>`). The subagent reads `.ai/agents/<id>.yaml` (canonical role). Adapters:
`.cursor/agents/<id>.md` (native Cursor) and `.claude/agents/<id>.md`.

| Task | Specialist id |
|------|---------------|
| Architecture, data modeling, ADRs, migrations review | `rails-architect` |
| Server-side Rails (models, controllers, services, jobs) | `backend-rails-developer` |
| UI with Hotwire / React + Inertia | `frontend-react-inertia-developer` |
| AWS, CI/CD, deployment, releases | `aws-devops-engineer` |
| QA, test plans, code review | `qa-engineer` |
| Security review and remediation | `security-reviewer` |
| Scope, user stories, product value | `product-owner` |
| Technical docs, runbooks, onboarding | `documentation-writer` |

Fallback (Ask mode / no Task): act as the role in `.ai/agents/<id>.yaml` with `@`-mentions.

## Follow the workflows

For multi-step work, you **MUST** follow the matching process in `.ai/workflows/`.
Do not invent an ad-hoc plan that skips its phases (testing, QA, documentation,
deployment). Available workflows:

- New feature → `.ai/workflows/new-feature.yaml`
- AWS deployment → `.ai/workflows/aws-deployment.yaml`
- Legacy onboarding → `.ai/workflows/legacy-onboarding.yaml`
- Production incident → `.ai/workflows/production-incident.yaml`

## Invoke the skills

Reusable capabilities live in `.ai/skills/` (e.g. `create-feature-spec`, `ponytail-review`, `security-audit`, `document-user-guide`). Read and follow the relevant `SKILL.md` when the request matches its purpose.

## Notes

- `.cursor/agents/` — native Cursor subagents (compiled from `.ai/agents/*/delegation`).
- `.cursor/rules/` adapts these standards for Cursor. Most are glob-scoped; `workflow-gates.mdc`, `minimalism.mdc`, and `project-structure.mdc` are always applied.
- `.cursor/hooks.json` enforces hard gates in Cursor (protected-branch push block, commit/secret checks, new-project gap detection).
- `.claude/` adapts them for Claude Code; its hooks run only in Claude Code.
- Standards are vendor-neutral — they apply regardless of the agent tool.
