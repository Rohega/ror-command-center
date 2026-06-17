# Rolos AI Development Studio

**Vendor-neutral AI engineering framework** for Rails, React/Inertia, AWS, MySQL, Odoo, and Textract workflows.

Use it with Cursor, Claude Code, OpenAI Codex, ChatGPT, GitHub Copilot, Gemini, or future AI coding agents. The canonical definitions live in `.ai/` — platform folders are thin adapters only.

---

## What Is This?

Rolos AI Development Studio structures AI-assisted software engineering like a real team:

- **13 specialized agents** (Product Owner, Rails Architect, DevOps, DBA, Security, QA, …)
- **15 reusable skills** (feature specs, architecture, code review, deployments, OCR pipeline, …)
- **4 end-to-end workflows** (new feature, production incident, AWS deploy, OCR processing)
- **9 engineering standards** (Rails, AWS, MySQL, API, security, testing, …)
- **7 document templates** (feature spec, ADR, QA plan, release checklist, …)

You stay in control. Agents ask questions, present options, draft artifacts, and wait for approval before writing files.

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
git clone <repo-url> rolos-ai-studio
cd rolos-ai-studio
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

**What gets copied (core):** `.ai/`, `.cursor/`, `.claude/{agents,hooks,skills,settings.json}`, `CLAUDE.md`, `docs/integrations/`, `docs/CLAUDE.md`, `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md`, `.github/copilot-instructions.md`, plus empty `docs/{architecture,specs,stories,design,runbooks,modules}/`.

**What is excluded:** `examples/`, `archive/`, `production/`, `.git/`, repo meta files, and the warehouse-mvp example docs (unless `--with-examples`).

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
  agents/               # Role definitions (YAML)
  skills/               # Reusable capabilities
  workflows/            # End-to-end processes
  standards/            # Engineering rules
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
3. Ask the agent to follow a workflow: *"Run the new feature workflow for invoice OCR"*
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

## How to Use with Codex

Load context at session start:

1. `CLAUDE.md` or `.ai/standards/collaboration.md`
2. Relevant agent YAML from `.ai/agents/`
3. Skill from `.ai/skills/<name>/SKILL.md`

See [docs/integrations/codex.md](docs/integrations/codex.md).

---

## Rails Project Workflow

Follow `.ai/workflows/new-feature.yaml`:

```text
Idea → User Stories → Architecture → Implementation → Review → QA → Release
```

| Phase | Skill | Agent |
|-------|-------|-------|
| Idea | `create-feature-spec` | Product Owner |
| Stories | `create-user-stories` | Product Owner |
| Architecture | `create-architecture-plan` | Rails Architect |
| Implementation | `create-api-endpoints` | Backend Rails Developer |
| Review | `review-rails-models`, `security-audit` | Code Reviewer |
| QA | `qa-plan` | QA Engineer |
| Release | `release-checklist` | Release Manager |

Standards: `.ai/standards/rails-development.md`, `mysql.md`, `testing.md`

---

## AWS Project Workflow

Follow `.ai/workflows/aws-deployment.yaml`:

```text
Planning → Infrastructure Review → Security Review → Deployment → Validation → Rollback Strategy
```

Skills: `aws-deploy-plan`, `nginx-puma-review`, `capistrano-review`, `security-audit`

Standard: `.ai/standards/aws-infrastructure.md`

---

## Security Recommendations

- Follow `.ai/standards/security.md` on every feature
- Run `security-audit` before production releases
- Never commit secrets — hooks warn on staged credential patterns
- IAM least privilege for Textract, S3, and RDS
- Dependency scanning (`bundle audit`) in CI

---

## Example Feature Lifecycle

1. **Product Owner** drafts `docs/specs/feature-invoice-ocr.md` via `create-feature-spec`
2. **Stories** → `docs/stories/invoice-ocr/US-001.md`
3. **Rails Architect** writes `docs/architecture/adr-0001-textract-pipeline.md`
4. **Backend Developer** implements models, jobs, Textract client
5. **Textract OCR Specialist** validates OCR workflow per `.ai/workflows/ocr-processing.yaml`
6. **Code Reviewer** runs `review-rails-models` + `security-audit`
7. **QA Engineer** produces QA plan; smoke test on staging
8. **Release Manager** completes checklist; Capistrano deploy to production

---

## Migration from Game Studio

This repository was refactored from **Claude Code Game Studios**. Original content is preserved in `archive/game-studio-original/`. See [UPGRADING.md](UPGRADING.md).

---

## License

MIT — see [LICENSE](LICENSE).
