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
- **End-to-end workflows** (new feature, production incident, AWS deploy)
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

Standards: `.ai/standards/development.md`, `.ai/standards/postgresql.md`, `.ai/standards/mysql.md`, `.ai/standards/testing.md`

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
| **Cursor** | `.cursor/rules/` | Rules reference `.ai/standards/` |
| **Claude Code** | `.claude/` | `CLAUDE.md` + slash skills |
| **OpenAI Codex** | `docs/integrations/codex.md` | Load `.ai/` context manually |
| **ChatGPT** | `docs/integrations/chatgpt.md` | Custom GPT or project instructions |
| **GitHub Copilot** | `docs/integrations/copilot.md` | `.github/copilot-instructions.md` pattern |
| **Gemini** | `docs/integrations/gemini.md` | Workspace instructions |

---

## Installation

Clone this framework, then run `install.sh` pointing at your project:

```bash
git clone <repo-url> ror-command-center
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

.cursor/rules/          # Cursor adapter → .ai/standards/
.claude/                # Claude Code adapter → .ai/

docs/
  integrations/         # Per-platform setup guides
  COLLABORATIVE-DESIGN-PRINCIPLE.md

archive/game-studio-original/   # Previous game-studio framework (preserved)
```

---

## How to Use with Cursor

1. Open the project in Cursor — rules in `.cursor/rules/` load automatically.
2. `project-structure.mdc` is always applied; others activate by file glob.
3. Ask the agent to follow a workflow: *"Run the new feature workflow for multi-warehouse stock transfer"*
4. Point to canonical skills: *"Use `.ai/skills/create-feature-spec/SKILL.md`"*

See [docs/integrations/cursor.md](docs/integrations/cursor.md).

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
