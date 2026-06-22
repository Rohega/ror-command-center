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

### How it stays in effect

Everything lives in **`.ai/` — the single source of truth**. Platform folders
(`.cursor/`, `.claude/`, `AGENTS.md`, `.github/`) are thin adapters that point to
it, never copies. A **router** guarantees `.ai/` is always considered: the 9 core
standards (collaboration, minimalism, development, project-bootstrap, testing,
security, git-workflow, code-review, documentation) load in every session, and
domain standards (frontend, API, data, async, auth, infra, legacy) load on demand
when you touch their area. In Cursor this is `.cursor/rules/ai-index.mdc`; in
Claude `CLAUDE.md`; in Codex/Copilot `AGENTS.md` / `copilot-instructions.md`.

New here? Start with the **[User Manual](docs/USER-MANUAL.md)**.

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
| Documentation | `document-module` (developer), `document-user-guide` (user) | Documentation Engineer |
| Deployment | `release-checklist`, `capistrano-review` | DevOps AWS Engineer |

**Definition of Done** (enforced by `.cursor/rules/workflow-gates.mdc`, always applied): no feature ships without RSpec tests, review, QA sign-off, and documentation — even on greenfield projects. New apps bootstrap RSpec first (`.ai/standards/project-bootstrap.md`).

Standards: `.ai/standards/development.md`, `.ai/standards/project-bootstrap.md`, `.ai/standards/postgresql.md`, `.ai/standards/mysql.md`, `.ai/standards/testing.md`, `.ai/standards/legacy-rails.md`

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
- Bootstrap RSpec first on new apps; no feature is done without tests, review, QA, and docs.
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

## Two ways to use it — pick your path

These are **independent** setups. They are easy to confuse, so here is the map:

| Path | What you get | How | What it installs |
|------|--------------|-----|------------------|
| **A · Cloud IDE** (most common) | Use the framework inside your Rails project with Cursor, Claude Code, Codex, … | Copy the core into your project → [Installation](#installation) (`install.sh`) | Nothing heavy — just config files (`.ai/`, `.cursor/`, `.claude/`, …) |
| **B · Local AI** (no cloud, no API keys) | Run the specialist team on your own machine via the `rorcc` CLI | Install Ollama + a model → [Local AI with Ollama](#local-ai-with-ollama-run-on-your-own-pc) (`setup.sh`) | Ollama + a multi-GB local model |

- **Path A does NOT install Ollama.** It only drops the framework files into your project so a cloud AI (Cursor/Claude) reads them.
- **Path B is the only one that installs an AI engine** (Ollama) on your computer.
- You can do **both**: run locally with Ollama *and* add the framework to a project for your cloud IDE.

> Going local (Path B)? First confirm your machine can run the models — see
> [Local model requirements](#local-model-requirements) below, then run
> `rorcc doctor` after install to re-check.

---

## Local AI with Ollama (run on your own PC)

Prefer no cloud, no API keys, zero per-token cost? The `rorcc` CLI compiles the
specialist agents into local [Ollama](https://ollama.com/) models. Ollama is a
runtime dependency you install separately — it is not part of this repo.

### Local model requirements

Local models are RAM-bound. Before installing, check what your machine can run:

| RAM | Model tier | Disk (model) | Experience |
|-----|-----------|--------------|------------|
| 8–16 GB | `qwen2.5-coder:7b` | ~5 GB | Works — everyday tasks |
| 24–32 GB | `qwen2.5-coder:14b` | ~9 GB | Better reasoning |
| 48 GB+ | `qwen2.5-coder:32b` | ~20 GB | Best local quality |
| < 8 GB | — | — | Not recommended (slow / limited) |

Check your machine in one command (works on **any** machine, even before
cloning/installing — reports RAM, CPU, disk, GPU and the recommended tier):

```bash
bash scripts/check-machine.sh
```

`setup.sh` runs this same check automatically and picks the tier for you;
`rorcc doctor` re-checks the full environment (RAM, Ollama, model, daemon) after
install. A GPU is optional but speeds inference up significantly. On **Windows +
WSL2**, raise the WSL memory limit in `.wslconfig` if needed (models need their
full size free in RAM).

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

Full command reference: [docs/rorcc-cli.md](docs/rorcc-cli.md). Ollama setup,
model tiers, hybrid mode, and IDE bridge: [docs/integrations/ollama.md](docs/integrations/ollama.md).
Local 7–14B models trade quality for privacy and offline use.

---

## Start a new project with Docker (only Docker required)

Want a brand-new, runnable Rails app with the framework already wired in, without
installing Ruby/Rails/Node on your machine? `rorcc init --docker` generates one
inside throwaway containers — **the only requirement is Docker**.

```bash
./install.sh --install-cli                 # one time: link the 'rorcc' command
rorcc init --docker tallerflow             # generates a Dockerized Rails app + framework
```

This is **independent from how you run the AI specialists**. They are two separate
choices:

| Choice | Options | Needs Ollama? |
|--------|---------|---------------|
| **How you create the project** | Local Ruby/Rails · **Docker only** (`rorcc init --docker`) | No |
| **How the AI specialists run** | Cursor / Claude (cloud IDE) · **Ollama** (local) · API key (`rorcc … --cloud`) | Only for the Ollama option |

So you can scaffold with Docker and then use Cursor (cloud) with **no Ollama at
all** — Ollama is only needed if you choose to run the agents locally.

Step-by-step onboarding (EN/ES): [docs/runbooks/new-project-docker-bootstrap.md](docs/runbooks/new-project-docker-bootstrap.md).

---

## Installation

> **This is Path A** (use with a cloud IDE). It copies the framework into an
> existing project; it does **not** install Ollama. For local AI, see
> [Local AI with Ollama](#local-ai-with-ollama-run-on-your-own-pc).

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

### Updating

`.ai/` is the **single source of truth**; `.cursor/`, `.claude/`, and `AGENTS.md`
are thin adapters that point to it. To update an installed project, pull the
latest framework and re-run the installer:

```bash
cd ror-command-center && git pull
./install.sh --force --backup /path/to/your-project   # --force refreshes files; --backup keeps .bak copies
```

Only edit files under `.ai/` (and project-specific docs); never hand-edit the
adapters — they are regenerated from `.ai/` on each install.

Full step-by-step guide: [docs/INSTALL.md](docs/INSTALL.md). New to the framework?
Read the [User Manual](docs/USER-MANUAL.md).

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

.cursor/rules/          # Cursor adapter → .ai/standards/ (ai-index.mdc router + workflow-gates.mdc always apply)
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
2. `ai-index.mdc` (the `.ai/` router), `project-structure.mdc`, `minimalism.mdc`, and `workflow-gates.mdc` always apply; others activate by file glob. `ai-index.mdc` loads the core standards every chat so `.ai/` is always considered.
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
