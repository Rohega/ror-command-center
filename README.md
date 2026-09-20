# RoR Command Center

**A production-grade Ruby on Rails AI engineering team.**

Not a generic agent framework: it accelerates real Rails work with specialists,
skills, workflows, and engineering standards. Canonical definitions live in
`.ai/` — platform folders (`.cursor/`, `.claude/`, `AGENTS.md`) are thin adapters
only.

**Documentation map:** [docs/README.md](docs/README.md) (install · contribute · warehouse example).  
**Beginner walkthrough:** [User Manual](docs/USER-MANUAL.md).

---

## Quick start — what do you want to do?

| I want to… | Go to | Needs Ollama? |
|------------|-------|---------------|
| Use the framework in my existing Rails project with Cursor / Claude | [Installation](#installation-path-a) | No |
| Run the AI specialists locally — no cloud, no API keys | [Local AI with Ollama](#local-ai-with-ollama) | Yes |
| Start a brand-new project with no local Ruby/Rails | [New project with Docker](#new-project-with-docker) | No |

These setups are **independent**:

- **How you create the project:** local Ruby/Rails · Docker only (`rorcc init --docker`).
- **How the AI runs:** Cursor / Claude (cloud IDE) · Ollama (local) · API key (`rorcc … --cloud`).

Ollama is **only** for running agents locally — never required just to install
the framework or scaffold a project. Detail for every route lives in the
[User Manual](docs/USER-MANUAL.md).

---

## Installation (Path A)

Copies the framework into an existing project. Does **not** install Ollama.

```bash
git clone https://github.com/Rohega/ror-command-center.git
cd ror-command-center
./install.sh /path/to/your-project
```

Useful flags: `--dry-run`, `--force`, `--backup`, `--with-examples`, `--install-cli`.
Step-by-step: [docs/INSTALL.md](docs/INSTALL.md).

Update later:

```bash
cd ror-command-center && git pull
./install.sh --force --backup /path/to/your-project
```

---

## Local AI with Ollama

```bash
cd ror-command-center && ./setup.sh   # asks once, then installs everything
rorcc                                 # interactive menu
```

Check hardware first: `bash scripts/check-machine.sh`.  
CLI reference: [docs/rorcc-cli.md](docs/rorcc-cli.md) · setup: [docs/integrations/ollama.md](docs/integrations/ollama.md).  
Undo: `./uninstall.sh` (try `--dry-run` first).

---

## New project with Docker

Only Docker required on the host — no local Ruby/Rails/Node.

```bash
./install.sh --install-cli
rorcc init --docker tallerflow
```

Docker scaffold ≠ Ollama. You can use Cursor in the cloud with no local model.
Full runbook: [docs/runbooks/new-project-docker-bootstrap.md](docs/runbooks/new-project-docker-bootstrap.md).

---

## What you get

- **8 specialists** — Product Owner, Architect, Backend, Frontend, DevOps AWS, QA, Documentation, Security  
- **Skills & workflows** — feature → deploy, legacy onboarding, incidents  
- **Standards** — Rails, AWS, PostgreSQL/MySQL, security, testing, minimalism, …  
- **Router** — core standards always load; domain standards on demand (Cursor `ai-index.mdc`, Claude `CLAUDE.md`, Codex/Copilot `AGENTS.md`)

Deep map: [`.ai/README.md`](.ai/README.md) · how to invoke specialists: [docs/how-to/use-agents.md](docs/how-to/use-agents.md).

**Definition of Done:** proportional — earned by complexity/risk (`.ai/standards/orchestration.md`). Never skip safety.

---

## Run a workflow (copy-paste)

From a directory that contains `.ai/` (this repo or a project you installed into).
No Ollama or API keys needed for `--plan`.

```bash
rorcc workflow new-feature --plan          # validate + show what would run (0 model calls)
rorcc workflow new-feature                 # interactive: Enter / s skip / q quit
rorcc workflow new-feature --auto          # one model turn per selected skill; still stops at gates
rorcc workflow new-feature --only idea,specification
```

| I want to… | Workflow name |
|------------|---------------|
| Build a feature from idea to deploy | `new-feature` |
| Plan/execute an AWS release | `aws-deployment` |
| Document a inherited Rails app first | `legacy-onboarding` |
| Handle a production outage | `production-incident` |

`--plan` prints **Declared / Selected / Omitted** units. Reviews whose files do
not exist (for example `capistrano-review` without `config/deploy.rb`) are
omitted so you do not pay for them. `--full` forces every declared skill.

Step-by-step (Cursor, Claude, CLI, gates, troubleshooting):
[docs/how-to/run-workflows.md](docs/how-to/run-workflows.md).
CLI flags: [docs/rorcc-cli.md](docs/rorcc-cli.md).
Spanish copy-paste of the same commands: [User Manual §4.3](docs/USER-MANUAL.md).

---

## Platform entry points

| Platform | Start here |
|----------|------------|
| Cursor | [docs/integrations/cursor.md](docs/integrations/cursor.md) |
| Claude Code | [docs/integrations/claude-code.md](docs/integrations/claude-code.md) |
| Ollama / `rorcc` | [docs/integrations/ollama.md](docs/integrations/ollama.md) |
| Codex / Copilot / ChatGPT / Gemini | [docs/integrations/](docs/integrations/) |

---

## Contribute · upgrade · license

- Contribute: [CONTRIBUTING.md](CONTRIBUTING.md)  
- From Game Studio: [UPGRADING.md](UPGRADING.md) (`archive/game-studio-original/`)  
- Security: follow `.ai/standards/security.md`; never commit secrets  
- License: MIT — [LICENSE](LICENSE)
