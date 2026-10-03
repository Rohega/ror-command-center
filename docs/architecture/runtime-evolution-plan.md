# Runtime Evolution Plan

This plan extends RORCC incrementally after native agent orchestration. The goal
is not to build a generic agent framework; each phase must solve a measured
engineering problem while preserving deterministic routing and proportional
Definition of Done.

## Guardrails

- Keep the Task Router authoritative about what work exists.
- Prefer deterministic checks over model judgment.
- Add no framework dependency unless the existing shell runtime cannot solve the problem.
- Each phase must be independently useful and testable.
- Do not implement a later phase merely because it appears in this roadmap.

## Phase 1 — Evidence-based verification loop

**Problem:** an agent can finish implementation and describe it as complete
without a uniform rule requiring concrete verification evidence.

Add a canonical runtime rule:

`execute → verify → fix from evidence → verify again → escalate/stop`

Rules:

- Use the narrowest relevant deterministic check first: targeted tests, lint,
  build, migration validation, security check, or an explicit project command.
- Do not use a second LLM as the default verifier when a deterministic check exists.
- A failed check must return concrete evidence into the next correction attempt.
- Do not repeat the same failed hypothesis indefinitely.
- After two failed correction attempts on the same problem, stop blind retries
  and escalate according to `native-agent-orchestration.md`.
- Size-S copy/visual work keeps proportional verification; do not run an entire
  suite when a focused check is sufficient.

**Exit:** native runtimes share this policy and tests enforce the contract.

## Phase 2 — Resumable workflow checkpoints

**Problem:** `.rorcc/runs/<run_id>/` records state, but a later session cannot
reliably continue the same run.

Add resumable run metadata and a command such as:

```bash
rorcc workflow resume latest
rorcc workflow resume <run-id>
```

Persist only what is needed to continue safely: workflow, request/classification,
signals, selected phases, statuses, current phase, attempts, gates, branch/commit
identity, and relevant verifier outcome.

**Exit:** interrupting and resuming produces the same remaining phase selection
without reclassifying the task.

## Phase 3 — Explicit failure transitions

**Problem:** workflows express dependencies and applicability, but failure
handling is mostly terminal.

Extend the existing graph only where useful, with bounded transitions such as:

`pass → next`, `fail → retry`, `retry exhausted → escalate/stop`.

Do not introduce a graph framework. Keep YAML and shell while they remain clear.

**Exit:** failure behavior is explicit, bounded, and covered by tests.

## Phase 4 — Lightweight execution trace

**Problem:** current metrics show status and elapsed time but not why retries or
escalations happened.

Add append-only `.rorcc/runs/<run-id>/events.jsonl` with a small stable event
schema for phase start/end, verification result, retry, gate, escalation, and
resume.

Do not log prompts, secrets, full model transcripts, or unnecessary source data.

**Exit:** a failed run can be reconstructed from events without reading chat history.

## Phase 5 — Run audit / improvement feedback

**Problem:** changes to skills/router are currently driven mostly by observation,
not aggregated execution evidence.

Add a read-only command such as:

```bash
rorcc audit-runs --last 20
```

Report repeated failures, retries, slow phases, unnecessary selected work, and
manual intervention. It may propose changes, but must never self-modify RORCC.

**Exit:** maintainers can make evidence-based improvements from local run data.

## Phase 6 — Documentation reconciliation

Perform a repository-wide documentation audit after the runtime phases stabilize.

At minimum reconcile:

- `README.md`
- `AGENTS.md`
- `CLAUDE.md`
- `.ai/README.md`
- `.ai/standards/orchestration.md`
- `.ai/standards/native-agent-orchestration.md`
- `docs/README.md`
- `docs/USER-MANUAL.md`
- `docs/rorcc-cli.md`
- `docs/how-to/run-workflows.md`
- platform integration docs for Cursor, Claude Code, Codex, ChatGPT/Copilot when applicable

Remove stale behavior descriptions and duplicated rules. Canonical behavior
must remain in `.ai/`; adapters and user documentation should point to it
instead of redefining it.

**Exit:** documented commands and runtime behavior match tests and the CLI, with
no known contradictory legacy instructions.

## Delivery order

1. Verification policy.
2. Check real usage before implementing resume.
3. Resume/checkpoints.
4. Failure transitions only if resume + verification reveal a real need.
5. Trace.
6. Run audit only after traces contain enough real executions.
7. Documentation reconciliation.

Each phase should use its own feature branch/PR once the preceding phase is
accepted. The present branch starts Phase 1 and records this roadmap.
