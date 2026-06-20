# Ollama Integration (Local AI)

Run the RoR Command Center specialist team **fully local** on your own PC using
[Ollama](https://ollama.com/) — no cloud, no API keys, zero per-token cost.

## How it fits

RoR Command Center is a knowledge framework (`.ai/`); it has no model of its own.
The `rorcc` CLI talks to **Ollama**, which you install separately. Ollama is a
runtime dependency (like Postgres or Docker), **not** part of this repo.

```text
rorcc (Bash + .ai/ knowledge)  ──HTTP──►  Ollama daemon (localhost:11434) + local models
```

## Prerequisites

| Tool | Why | Install |
|------|-----|---------|
| Ollama | Runs the local model | `curl -fsSL https://ollama.com/install.sh \| sh` |
| `curl` | rorcc → Ollama HTTP | Pre-installed on most systems |
| `jq` | Build/parse chat JSON | `apt install jq` / `brew install jq` |

Pick a base model by RAM (see `ollama/models.yaml`):

| RAM | Model | Pull |
|-----|-------|------|
| 8–16 GB | `qwen2.5-coder:7b` | `ollama pull qwen2.5-coder:7b` |
| 24–32 GB | `qwen2.5-coder:14b` | `ollama pull qwen2.5-coder:14b` |
| 48 GB+ | `qwen2.5-coder:32b` | `ollama pull qwen2.5-coder:32b` |

> Local 7–14B models are below Claude/GPT for complex architecture. The value of
> local is privacy, zero cost, and offline use. For hard problems, use a cloud
> client (Cursor/Claude Code) and keep local for everyday tasks.

## Easy install (non-technical users)

One command installs everything (Ollama, a model, the `rorcc` CLI, and the
specialists), then you just type `rorcc` and pick from a menu. Works on Linux,
macOS, and Windows + WSL.

```bash
curl -fsSL https://raw.githubusercontent.com/Rohega/ror-command-center/main/setup.sh | bash
```

The script asks for **one** confirmation, then runs on its own. It detects your
RAM, picks a suitable model, and is **idempotent** (safe to re-run). When done:

```bash
rorcc            # opens an interactive menu — pick a specialist by number
```

> Running piped/non-interactively? Accept upfront with:
> `curl -fsSL <url>/setup.sh | RORCC_YES=1 bash`

## Quickstart (manual / developers)

```bash
# 1. Install Ollama + pull a model
curl -fsSL https://ollama.com/install.sh | sh
ollama pull qwen2.5-coder:7b

# 2. Check your environment
rorcc doctor

# 3. Compile an agent into a local Ollama model
rorcc build-agent rails-architect

# 4. Chat with it locally
rorcc agent rails-architect
```

In the chat: type your message, `/reset` to clear history, `/exit` to quit.

## How `build-agent` works

`rorcc build-agent <name>` reads `.ai/agents/<name>.yaml`, inlines every
`.ai/standards/*` it references, and writes an Ollama `Modelfile` with that text
as the `SYSTEM` prompt. It then runs `ollama create rorcc-<name>`. The `.ai/`
files stay the single source of truth — the model is regenerated, never duplicated
by hand. Generated files live in `<project>/.rorcc/build/<name>/`.

## Configuration

| Variable | Default | Purpose |
|----------|---------|---------|
| `RORCC_MODEL` | `qwen2.5-coder:7b` | Base model used by `build-agent` |
| `OLLAMA_HOST` | `http://localhost:11434` | Ollama endpoint |
| `RORCC_MAX_CHARS` | _(unset)_ | Hard-cap the system prompt size (truncate) for small models |
| `RORCC_WARN_CHARS` | `32000` | Warn when the assembled prompt exceeds this size |

After editing anything under `.ai/`, recompile so the change reaches the models:

```bash
rorcc update                 # rebuild every compiled agent
rorcc update rails-architect # or just one
```

Replies stream token-by-token in `rorcc agent`, so you see output as it's generated.

```bash
RORCC_MODEL=qwen2.5-coder:14b rorcc build-agent backend-rails-developer
```

## Run a skill

Beyond chatting with an agent, you can run a full skill (`.ai/skills/<name>`). It
loads the skill's responsible agent plus the skill instructions and any templates,
then opens a guided session:

```bash
rorcc skill create-feature-spec          # local
rorcc skill create-feature-spec --cloud  # hybrid
```

If the skill's agent isn't compiled yet, `rorcc` builds it automatically.

## Run a full workflow

Run an end-to-end process (`.ai/workflows/<name>.yaml`) phase by phase. Each phase
runs its skill with the right agent and pauses at its gate for your confirmation:

```bash
rorcc workflow new-feature           # local
rorcc workflow new-feature --cloud   # hybrid
```

At each phase: `Enter` to run, `s` to skip, `q` to quit. After a phase with a
gate, you confirm it before moving on. Available workflows: `new-feature`,
`legacy-onboarding`, `aws-deployment`, `production-incident`.

## Hybrid mode (local + cloud)

Use local models for everyday tasks and a cloud model for hard architecture work —
same agents, same assembled prompt. The cloud backend sends the agent's role +
standards as the system message.

```bash
# OpenAI (or any OpenAI-compatible endpoint via RORCC_CLOUD_BASE)
export OPENAI_API_KEY=sk-...
rorcc agent rails-architect --cloud

# Anthropic
export ANTHROPIC_API_KEY=sk-ant-...
export RORCC_CLOUD_PROVIDER=anthropic
rorcc agent rails-architect --cloud
```

| Variable | Default | Purpose |
|----------|---------|---------|
| `RORCC_BACKEND` | `local` | `local` (Ollama) or `cloud` |
| `RORCC_CLOUD_PROVIDER` | `openai` | `openai` or `anthropic` |
| `RORCC_CLOUD_MODEL` | `gpt-4o` / `claude-3-5-sonnet-latest` | Cloud model id |
| `RORCC_CLOUD_BASE` | `https://api.openai.com/v1` | OpenAI-compatible base URL |

Cloud mode needs no `build-agent` step — the prompt is assembled on the fly.
`rorcc doctor` reports whether a cloud key is set. Cloud support is best-effort;
provider APIs change over time.

## Use Ollama from Cursor / Claude Code (bridge)

Want your existing IDE to use the local model? `rorcc proxy` prints the exact
config and can launch a gateway:

```bash
rorcc proxy            # show Cursor + Claude Code setup
rorcc proxy --start    # launch a LiteLLM gateway (needs: pip install litellm)
```

- **Cursor**: add a custom OpenAI model with base URL `http://localhost:11434/v1`
  (Ollama is OpenAI-compatible). Verification from Cursor's servers may fail for a
  purely local URL depending on the version — best-effort.
- **Claude Code**: speaks the Anthropic API, so run `rorcc proxy --start` (LiteLLM)
  and set `ANTHROPIC_BASE_URL=http://localhost:4000`.

This bridge is best-effort; IDE client behavior changes between versions.

## Available agents

`rails-architect`, `backend-rails-developer`, `frontend-react-inertia-developer`,
`aws-devops-engineer`, `qa-engineer`, `documentation-writer`, `product-owner`,
`security-reviewer`.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `ollama daemon not reachable` | Run `ollama serve` (or restart the Ollama app) |
| `base model missing` | `ollama pull qwen2.5-coder:7b` |
| `jq is required` | `apt install jq` / `brew install jq` |
| Slow / poor answers | Use a larger tier model, or switch to a cloud client for that task |
