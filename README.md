# RoR Command Center

**A production-grade Ruby on Rails AI engineering team.**

RoR Command Center is **not** a generic agent framework. Its purpose is to accelerate
real, production-grade Ruby on Rails development using proven architecture, conventions,
and operational practices — and to build real business applications faster, not
experimental demos.

Use it with Cursor, Claude Code, OpenAI Codex, ChatGPT, GitHub Copilot, Gemini, or future
AI coding agents. The canonical definitions live in `.ai/` — platform folders are thin
adapters only.

---

## Core Philosophy

- **Rails First**
- **Convention Over Configuration**
- **Production Ready**
- **AWS Native**
- **Maintainable Code**
- **Testable Code**
- **Senior Engineer Standards**

---

## Specialization

Ruby on Rails 7+ and 8+ · PostgreSQL & MySQL · Sidekiq · ActiveJob · Devise ·
ActiveAdmin · Hotwire · React + Inertia · AWS · Docker · Capistrano · Kamal ·
REST APIs · Background Processing · OCR Pipelines · WhatsApp Integrations ·
Enterprise Applications.

---

## What Is This?

RoR Command Center structures AI-assisted Rails engineering like a real senior team:

- **8 specialists** (Product Owner, Rails Architect, Backend, Frontend, DevOps AWS, QA, Documentation, Security)
- **Reusable skills** (feature specs, architecture, code review, UX specs, deployments, …)
- **End-to-end workflows** (new feature, legacy onboarding, production incident, AWS deploy)
- **Engineering standards** (Rails, frontend, UX/accessibility, AWS, PostgreSQL/MySQL, API, security, testing, …)
- **Document templates** (feature spec, ADR, UX spec, QA plan, release checklist, …)

You stay in control. Agents ask questions, present options, draft artifacts, and wait for approval before writing files.

---

## Available Specialists

1. **Product Owner** — scope, specs, acceptance criteria
2. **Rails Architect** — architecture, data modeling, migrations & rollback strategy
3. **Backend Engineer** — models, service objects, jobs, REST APIs
4. **Frontend Engineer** — Hotwire and React + Inertia, UX/accessibility
5. **DevOps AWS Engineer** — AWS, Docker, Capistrano/Kamal, releases
6. **QA Engineer** — test plans, code review, quality gates
7. **Documentation Engineer** — module docs, ADRs, runbooks
8. **Security Engineer** — security review across every feature

---

## Feature Pipeline

Every feature request follows:

```text
Idea → Specification → Architecture → Implementation Plan → Development → Testing → Documentation → Deployment
```

| Phase | Skill | Specialist |
|-------|-------|-----------|
| Idea | `create-feature-spec` | Product Owner |
| Specification | `create-user-stories` | Product Owner |
| Architecture | `create-architecture-plan` | Rails Architect |
| Implementation Plan | `create-architecture-plan` | Rails Architect |
| Development | `create-api-endpoints`, `review-db-migrations` | Backend & Frontend Engineers |
| Testing | `qa-plan` | QA Engineer |
| Documentation | `document-module` | Documentation Engineer |
| Deployment | `release-checklist`, `capistrano-review` | DevOps AWS Engineer |

Standards: `.ai/standards/development.md`, `.ai/standards/postgresql.md`, `.ai/standards/mysql.md`, `.ai/standards/testing.md`, `.ai/standards/legacy-rails.md`

---

## Legacy & Reverse-Documentation

Inherited a Rails app with missing or stale specs? RoR Command Center can
reverse-document it and plan safe, incremental modernization.

```text
Discovery → Inventory → Risk Assessment → Reverse Documentation → Modernization Plan
```

| Artifact | Path |
|----------|------|
| Standard | `.ai/standards/legacy-rails.md` (characterization tests, seams, strangler fig, Rails upgrades) |
| Skill | `.ai/skills/reverse-document-legacy/SKILL.md` (audit app → system map, module docs, retrospective ADRs, risks) |
| Workflow | `.ai/workflows/legacy-onboarding.yaml` |
| Templates | `.ai/templates/legacy-module-audit.md`, `.ai/templates/modernization-plan.md`, `.ai/templates/retrospective-adr.md` |

Start by running the `reverse-document-legacy` skill in `map` mode, then follow the
`legacy-onboarding` workflow. All changes stay documentation-only until a modernization
plan is approved.

---

## Operating Rules

- Follow Rails conventions whenever possible.
- Avoid unnecessary abstractions.
- Prefer Service Objects over fat controllers.
- Prefer ActiveJob for async work.
- Generate migration strategies and rollback plans.
- Include security, monitoring, and deployment considerations.
- Assume production deployment on AWS.
- Output must always be actionable and production-focused.

---

## Supported AI Platforms

| Platform | Integration | Entry Point |
|----------|-------------|-------------|
| **Cursor** | `.cursor/rules/` + `AGENTS.md` | Rules reference `.ai/standards/`; `AGENTS.md` binds agents/workflows |
| **Claude Code** | `.claude/` | `CLAUDE.md` + slash skills |
| **OpenAI Codex** | `docs/integrations/codex.md` + `AGENTS.md` | `AGENTS.md` auto-loads; `.ai/` for deep context |
| **ChatGPT** | `docs/integrations/chatgpt.md` | Custom GPT or project instructions |
| **GitHub Copilot** | `docs/integrations/copilot.md` | `.github/copilot-instructions.md` pattern |
| **Gemini** | `docs/integrations/gemini.md` | Workspace instructions |
| **Ollama (local)** | `docs/integrations/ollama.md` | `rorcc` CLI runs agents on your own PC |

---

## Local AI with Ollama (run on your own PC)

Prefer no cloud, no API keys, zero per-token cost? The `rorcc` CLI compiles the
specialist agents into local [Ollama](https://ollama.com/) models. Ollama is a
runtime dependency you install separately — it is not part of this repo.

Non-technical? One command sets up everything:

```bash
curl -fsSL https://raw.githubusercontent.com/Rohega/ror-command-center/main/setup.sh | bash
rorcc                               # interactive menu — pick a specialist by number
```

Developers / manual setup:

```bash
./install.sh --install-cli          # link the 'rorcc' command into your PATH
rorcc doctor                        # check Ollama, models, environment
rorcc build-agent rails-architect   # compile .ai/agents/rails-architect.yaml → local model
rorcc agent rails-architect         # chat locally  (--cloud for hybrid)
rorcc skill create-feature-spec     # run a skill with its responsible agent
rorcc workflow new-feature          # run a full workflow, phase by phase
```

Start a brand-new project with **only Docker** (no local Ruby/Rails):

```bash
rorcc init --docker tallerflow      # generates a Dockerized Rails app + framework
```

Step-by-step onboarding: [docs/runbooks/new-project-docker-bootstrap.md](docs/runbooks/new-project-docker-bootstrap.md).

Full command reference: [docs/rorcc-cli.md](docs/rorcc-cli.md). Ollama setup,
model tiers, hybrid mode, and IDE bridge: [docs/integrations/ollama.md](docs/integrations/ollama.md).
Local 7–14B models trade quality for privacy and offline use.

---

## Installation

Clone this framework, then run `install.sh` pointing at your project:

```bash
git clone https://github.com/Rohega/ror-command-center.git
cd ror-command-center
./install.sh /path/to/your-project
```

The script copies the framework **core** into your project and creates an empty `docs/` scaffolding — it does **not** copy example-specific content. Existing files are skipped unless you pass `--force`.

| Flag | Effect |
|------|--------|
| `--dry-run` | Show what would be copied without writing anything |
| `--force` | Overwrite files that already exist in the target |
| `--backup` | Save conflicting files as `<file>.bak` before overwriting |
| `--with-examples` | Also copy `examples/` and the warehouse example docs |
| `-h`, `--help` | Show usage |

Full step-by-step guide: [docs/INSTALL.md](docs/INSTALL.md).

**Prerequisites (recommended):**
- Git, Bash
- For Claude Code: `@anthropic-ai/claude-code`
- For hooks: `jq`, Python 3 (optional, hooks degrade gracefully)

> Prefer manual control? You can still copy or merge `.ai/`, `.cursor/`, and `.claude/` into your application repository by hand.

---

## Repository Structure

```text
.ai/                    # SINGLE SOURCE OF TRUTH
  agents/               # 8 Rails specialist role definitions (YAML)
  skills/               # Reusable capabilities
  workflows/            # End-to-end processes
  standards/            # Engineering rules (Rails, AWS, PostgreSQL/MySQL, …)
  templates/            # Document templates

.cursor/rules/          # Cursor adapter → .ai/standards/ (workflow-gates.mdc always applies)
.cursor/hooks.json      # Cursor hard gates (protected-branch push block, secret/commit checks)
.cursor/hooks/          # Cursor hook scripts
.claude/                # Claude Code adapter → .ai/

docs/
  integrations/         # Per-platform setup guides
  COLLABORATIVE-DESIGN-PRINCIPLE.md

archive/game-studio-original/   # Previous game-studio framework (preserved)
```

---

## How to Use with Cursor

1. Open the project in Cursor — rules in `.cursor/rules/` load automatically.
2. `project-structure.mdc`, `minimalism.mdc`, and `workflow-gates.mdc` always apply; others activate by file glob.
3. `workflow-gates.mdc` enforces the Definition of Done (RSpec tests, review, QA, docs) even on greenfield projects; `.cursor/hooks.json` adds hard gates (e.g. blocks direct push to `main`).
4. **New to this?** Follow the 5-minute quickstart in [docs/integrations/cursor.md](docs/integrations/cursor.md#quickstart-5-minutes).
5. Plan in **Ask mode**, then switch to **Agent mode** to implement.

See [docs/integrations/cursor.md](docs/integrations/cursor.md) for concepts, copy-paste recipes, and troubleshooting.

---

## How to Use with Claude Code

1. Run `claude` in the project root.
2. `CLAUDE.md` loads standards and collaboration protocol.
3. Invoke skills: `/create-feature-spec`, `/security-audit`, `/release-checklist`
4. Spawn agents for specialized work — adapters in `.claude/agents/` read `.ai/agents/*.yaml`

See [docs/integrations/claude-code.md](docs/integrations/claude-code.md).

---

## Security Recommendations

- Follow `.ai/standards/security.md` on every feature
- Run `security-audit` before production releases
- Never commit secrets — hooks warn on staged credential patterns
- IAM least privilege for S3, RDS, and every service role
- Dependency scanning (`bundle audit`) in CI

---

## Migration from Game Studio

This repository was refactored from **Claude Code Game Studios**. Original content is preserved in `archive/game-studio-original/`. See [UPGRADING.md](UPGRADING.md).

---

## License

MIT — see [LICENSE](LICENSE).
