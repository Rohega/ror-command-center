# RoR Command Center — Agent Entry Point

Production-grade Ruby on Rails AI engineering team. **Canonical definitions live in `.ai/`** — this file is the entry point that binds them for every agent session (Cursor, Codex, and any AGENTS.md-aware tool).

Do not duplicate content here; reference the source of truth.

## Always apply

- **Standards** in `.ai/standards/` govern every change. Minimalism (`.ai/standards/minimalism.md`) and the project structure are non-negotiable defaults.
- **Collaboration protocol** (`.ai/standards/collaboration.md`): Question → Options → Decision → Draft → Approval. Ask before writing files; no commits without explicit instruction.
- **Git workflow** (`.ai/standards/git-workflow.md`): work on `feature/<ticket>-<slug>` branches, Conventional Commits, never commit directly to `main`.

## Use the roles

When a task matches a role, adopt the matching definition in `.ai/agents/`:

| Task | Role |
|------|------|
| Architecture, data modeling, ADRs, migrations review | `rails-architect` |
| Server-side Rails (models, controllers, services, jobs) | `backend-rails-developer` |
| UI with Hotwire / React + Inertia | `frontend-react-inertia-developer` |
| AWS, CI/CD, deployment, releases | `aws-devops-engineer` |
| QA, test plans, code review | `qa-engineer` |
| Security review and remediation | `security-reviewer` |
| Scope, user stories, product value | `product-owner` |
| Technical docs, runbooks, onboarding | `documentation-writer` |

## Follow the workflows

For multi-step work, follow the matching process in `.ai/workflows/`:

- New feature → `.ai/workflows/new-feature.yaml`
- AWS deployment → `.ai/workflows/aws-deployment.yaml`
- Legacy onboarding → `.ai/workflows/legacy-onboarding.yaml`
- Production incident → `.ai/workflows/production-incident.yaml`

## Invoke the skills

Reusable capabilities live in `.ai/skills/` (e.g. `create-feature-spec`, `ponytail-review`, `security-audit`). Read and follow the relevant `SKILL.md` when the request matches its purpose.

## Notes

- `.cursor/rules/` adapts these standards for Cursor (glob-scoped auto-attach).
- `.claude/` adapts them for Claude Code; its hooks run only in Claude Code.
- Standards are vendor-neutral — they apply regardless of the agent tool.
