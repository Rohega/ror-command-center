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
- CLI / workflows → `orchestration`

Full navigable index: `.ai/README.md`. Cursor loads this automatically via
`.cursor/rules/ai-index.mdc`; other tools load this file (`AGENTS.md`).

## Always apply

- **Standards** in `.ai/standards/` govern every change. Minimalism (`.ai/standards/minimalism.md`) and the project structure are non-negotiable defaults.
- **Engineering gates / Definition of Done** (`.ai/standards/orchestration.md`):
  strong and **proportional**. Artifacts are earned by complexity, risk, or
  uncertainty — do not invent a spec, ADR, or module doc for a trivial change.
- **Collaboration protocol** (`.ai/standards/collaboration.md`): Question → Options → Decision → Draft → Approval. Ask before writing files; no commits without explicit instruction.
- **Git workflow** (`.ai/standards/git-workflow.md`): work on `feature/<ticket>-<slug>` branches, Conventional Commits, never commit directly to `main`.

## Definition of Done (proportional)

Canonical table: `.ai/standards/orchestration.md` (Proportional Definition of Done).
Classify the request once (S/M/L/XL + signals), then run only the earned phases
in `.ai/workflows/new-feature.yaml` (`applies_when` + path router).

**Never omit** regardless of size: security when it applies; validation at trust
boundaries; protection against data loss; tests for non-trivial logic; migration
review when migrations exist.

**Do omit** for size S with no risk signals: Feature Spec, User Stories, ADR,
Technical Design, module documentation, and full QA.

When creating a Rails app **from scratch**, the first step is the test stack:
follow `.ai/standards/project-bootstrap.md` (RSpec + FactoryBot + SimpleCov +
generators) **before** writing application code.

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
Honor `applies_when` after one classification — do not skip earned safety phases,
and do not invent omitted ones. Available workflows:

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
