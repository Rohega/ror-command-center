# rorcc — CLI Manual

`rorcc` runs the RoR Command Center specialist team locally on [Ollama](https://ollama.com/)
(or a cloud LLM in hybrid mode). It compiles `.ai/agents` into models and drives
skills and workflows. The `.ai/` directory stays the single source of truth — models
are generated from it, never duplicated by hand.

## Install

Non-technical, one command (Linux/macOS/WSL). Already cloned the repo:

```bash
cd ror-command-center && ./setup.sh
```

Or a remote one-liner — piped into `bash` it runs non-interactively, so accept
upfront with `RORCC_YES=1`:

```bash
curl -fsSL https://raw.githubusercontent.com/Rohega/ror-command-center/main/setup.sh | RORCC_YES=1 bash
```

Manual:

```bash
./install.sh --install-cli      # link 'rorcc' into ~/.local/bin or /usr/local/bin
```

Runtime dependencies (verified by `rorcc doctor`): [Ollama](https://ollama.com/),
`curl`, and `jq`. Ollama is external (installed separately), like Postgres or Docker.

## Uninstall

Undo it with `./uninstall.sh` (or `rorcc uninstall`) — interactive, previewable
with `--dry-run`. `--models` also deletes base models, `--ollama` removes Ollama
itself, and `--project <dir>` removes framework files copied into a project.
It leaves `jq`/`zstd`/`git` alone and keeps your own files in `--project` mode.

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
| `rorcc workflow <name> --plan` | Preflight + deterministic router; print selected/omitted units. No LLM, no project writes |
| `rorcc workflow <name> --auto` | Skip per-phase `[Enter]`; one-shot model turn per unit. Gates still need a human |
| `rorcc workflow <name> --only a,b` | Run only those phase ids (prior phases are treated as already done) |
| `rorcc workflow <name> --skip a` | Skip those phases; dependents follow `depends_on` |
| `rorcc workflow <name> --full` | Disable the router; run every declared unit |
| `rorcc workflow <name> --request "…"` | Classify once (heuristic, 0 LLM) then apply `applies_when` |
| `rorcc workflow <name> --size S\|M\|L\|XL` | Override size (implies classification) |
| `rorcc workflow <name> --signals a,b` | Override signals (implies classification) |
| `rorcc builder [--plan]` | Fixed questions, write a plan, and on `--accept` run `new-feature`. `--plan` prints the command and writes nothing |
| `rorcc proxy [--start]` | Show IDE (Cursor/Claude Code) config; `--start` runs a LiteLLM gateway |
| `rorcc uninstall [opts]` | Remove what `setup.sh` installed (`--models`, `--ollama`, `--project <dir>`, `--dry-run`) |
| `rorcc help` | Show usage |

In a chat session: type your message, `/reset` clears history, `/exit` quits.

Want to build your own specialist with `build-agent`? Step-by-step guide:
[docs/how-to/create-specialist-agent.md](how-to/create-specialist-agent.md).

## Typical flows

First-time local setup:

```bash
rorcc doctor                     # see what's missing
ollama pull qwen2.5-coder:7b     # pull a base model
rorcc build-agent rails-architect
rorcc agent rails-architect
```

Run a process end to end — **start with `--plan`** (no Ollama, no API keys):

```bash
rorcc workflow new-feature --plan              # what will run; 0 LLM calls
rorcc workflow new-feature --plan --request "Cambiar el texto Login por Entrar"
rorcc workflow new-feature                     # Enter / s skip / q quit
rorcc workflow new-feature --auto              # one-shot per selected skill; gates still ask
rorcc workflow new-feature --only development,testing
rorcc workflow new-feature --skip deployment
rorcc workflow new-feature --plan --full       # do not omit path-based reviews
```

How to pick a workflow, read `--plan` output, and recover from `blocked` /
`workflow invalid`: [docs/how-to/run-workflows.md](how-to/run-workflows.md).

## Workflow runner

`rorcc workflow` reads `.ai/workflows/<name>.yaml`, fails closed in preflight,
then runs **selected skills** (not a redundant agent chat on top of each skill).

| Flag | What happens |
|------|----------------|
| `--plan` | Preflight + router. Prints declared / selected / omitted units. No writes |
| `--auto` | No per-phase `[Enter]`. One model completion per selected unit. **Gates still require `y`** |
| `--only a,b` | Only those **phase ids**. Other phases are skipped; their absence does not block |
| `--skip a` | Skip those ids; later phases that `depends_on` them become `blocked` |
| `--full` | Ignore path-based omission; run every declared skill |
| `--local` / `--cloud` | Backend |

**Units:** one selected skill (or one agent if the phase has no skills). In this
repository `new-feature` is usually **14 declared / 12 selected** because
`review-rails-models` and `capistrano-review` have no matching files.

**After a real run** (not `--plan`): `.rorcc/runs/<run-id>/{state,metrics,summary}.tsv`
(gitignored).

Workflow-invoked **cloud** skills send a lean prompt (`purpose` + skill +
templates). Standalone `rorcc skill` still inlines referenced standards.

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
| `RORCC_LEAN` | `1` during `workflow` | Cloud: specialist purpose + skill only (set by the runner) |
| `RORCC_WORKFLOW_AUTO` | `1` with `--auto` | One-shot chat turn per unit |
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
| `workflow invalid` | Preflight failed — read `error:` lines; fix YAML before spending tokens |
| Phase `blocked` | A `depends_on` phase was skipped/failed; re-run it or use `--only` |
| Skill omitted in `--plan` | No matching `paths:` on disk; pass `--full` if you still need it |

See also: [docs/integrations/ollama.md](integrations/ollama.md).
