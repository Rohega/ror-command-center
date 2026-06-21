# rorcc — CLI Manual

`rorcc` runs the RoR Command Center specialist team locally on [Ollama](https://ollama.com/)
(or a cloud LLM in hybrid mode). It compiles `.ai/agents` into models and drives
skills and workflows. The `.ai/` directory stays the single source of truth — models
are generated from it, never duplicated by hand.

## Install

Non-technical, one command (Linux/macOS/WSL):

```bash
curl -fsSL https://raw.githubusercontent.com/Rohega/ror-command-center/main/setup.sh | bash
```

Manual:

```bash
./install.sh --install-cli      # link 'rorcc' into ~/.local/bin or /usr/local/bin
```

Runtime dependencies (verified by `rorcc doctor`): [Ollama](https://ollama.com/),
`curl`, and `jq`. Ollama is external (installed separately), like Postgres or Docker.

## Commands

| Command | Description |
|---------|-------------|
| `rorcc` | Interactive menu — pick a specialist by number (best for non-devs) |
| `rorcc init <project>` | Scaffold a new project with the `.ai/` framework |
| `rorcc init --docker <project>` | Scaffold a full Dockerized Rails app (MySQL, no local Ruby/Rails) with the RSpec test stack pre-wired + framework |
| `rorcc doctor` | Check Ollama, models, RAM, and cloud-key readiness |
| `rorcc build-agent <name>` | Compile `.ai/agents/<name>.yaml` (+ standards) into model `rorcc-<name>` |
| `rorcc update [name]` | Recompile agents after editing `.ai/` (all, or just one) |
| `rorcc agent <name> [--cloud]` | Chat with an agent (local by default, `--cloud` for hybrid) |
| `rorcc skill <name> [--cloud]` | Run a `.ai/skills/<name>` skill with its responsible agent |
| `rorcc workflow <name> [--cloud]` | Run a `.ai/workflows/<name>` end to end, phase by phase |
| `rorcc proxy [--start]` | Show IDE (Cursor/Claude Code) config; `--start` runs a LiteLLM gateway |
| `rorcc help` | Show usage |

In a chat session: type your message, `/reset` clears history, `/exit` quits.

## Typical flows

First-time local setup:

```bash
rorcc doctor                     # see what's missing
ollama pull qwen2.5-coder:7b     # pull a base model
rorcc build-agent rails-architect
rorcc agent rails-architect
```

Run a process end to end:

```bash
rorcc workflow new-feature
# Phase 1 Idea → create-feature-spec (product-owner) … confirm gate … next phase
```

After editing an agent or standard under `.ai/`:

```bash
rorcc update                     # rebuild every compiled agent
```

## Docker bootstrap (no local Ruby/Rails)

`rorcc init --docker <project>` creates a complete, runnable Rails app using only
Docker on the host — no Ruby, Rails, or Node installed locally. It generates the
app inside a throwaway `ruby:3.3` container, drops in a generic **MySQL** dev
stack (`Dockerfile.dev`, `docker-compose.yml`, entrypoint, `config/database.yml`),
wires the mandatory **RSpec** test stack (RSpec + FactoryBot + SimpleCov +
`config.generators :rspec`, per `.ai/standards/project-bootstrap.md`) instead of
Minitest, installs the `.ai/` framework, and initializes git.

```bash
rorcc init --docker tallerflow
cd tallerflow
docker compose run --rm web rails db:create db:migrate
docker compose up                # -> http://localhost:3000
```

Requirements: Docker Desktop (enable WSL integration on Windows). The database
name defaults to the project directory name (e.g. `tallerflow_development`),
overridable via `DATABASE_NAME` in the generated `.env`.

Full step-by-step onboarding (with troubleshooting and rollback):
`docs/runbooks/new-project-docker-bootstrap.md`.

## Backends

- **local** (default): the compiled Ollama model `rorcc-<name>`, fully offline.
- **cloud** (`--cloud` or `RORCC_BACKEND=cloud`): the agent's role + standards are
  assembled and sent as the system prompt to OpenAI or Anthropic. No `build-agent`
  needed. Use local for everyday work, cloud for hard architecture problems.

## Environment variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `RORCC_MODEL` | `qwen2.5-coder:7b` | Base Ollama model for `build-agent` |
| `OLLAMA_HOST` | `http://localhost:11434` | Ollama endpoint |
| `RORCC_BACKEND` | `local` | `local` or `cloud` |
| `RORCC_CLOUD_PROVIDER` | `openai` | `openai` or `anthropic` |
| `RORCC_CLOUD_MODEL` | `gpt-4o` / `claude-3-5-sonnet-latest` | Cloud model id |
| `RORCC_CLOUD_BASE` | `https://api.openai.com/v1` | OpenAI-compatible base URL |
| `RORCC_WARN_CHARS` | `32000` | Warn when the assembled prompt exceeds this size |
| `RORCC_MAX_CHARS` | _(unset)_ | Hard-cap (truncate) the system prompt for small models |
| `RORCC_PROXY_PORT` | `4000` | Port for the `proxy --start` LiteLLM gateway |
| `OPENAI_API_KEY` / `ANTHROPIC_API_KEY` | _(unset)_ | Cloud credentials |

## Use from Cursor / Claude Code

```bash
rorcc proxy            # prints exact setup for both IDEs
rorcc proxy --start    # launches a LiteLLM gateway (pip install litellm)
```

- **Cursor**: add a custom OpenAI model with base URL `http://localhost:11434/v1`.
- **Claude Code**: `rorcc proxy --start`, then `ANTHROPIC_BASE_URL=http://localhost:4000`.

Best-effort — IDE behavior changes between versions.

## Caveats

- Local 7–14B models are below Claude/GPT for complex architecture. The win is
  privacy, zero cost, and offline use.
- Small models have limited context; `build-agent` warns (and can truncate via
  `RORCC_MAX_CHARS`) when the assembled prompt is large.
- Cloud support is best-effort; provider APIs evolve.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `ollama daemon not reachable` | `ollama serve` (or restart the Ollama app) |
| `base model missing` | `ollama pull qwen2.5-coder:7b` |
| `jq is required` | `apt install jq` / `brew install jq` |
| `model 'rorcc-<name>' not found` | `rorcc build-agent <name>` first |
| Cloud: empty/failed response | check `OPENAI_API_KEY`/`ANTHROPIC_API_KEY` and network |
| Slow / poor answers | use a larger model tier, or `--cloud` for that task |

See also: [docs/integrations/ollama.md](integrations/ollama.md).
