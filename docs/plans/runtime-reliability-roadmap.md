# RORCC Runtime Reliability Roadmap

Goal: improve reliability only where it solves a real failure mode. Keep the current deterministic router and native-agent model; do not add a generic graph framework.

Status: Phase 1 is implemented in PR #53 and is being validated before merge.

## Phase 1 — Verification loop (implement now)

Problem: a phase can finish because the execution unit returned success, without deterministic evidence that the produced code works.

Scope:
- Add an opt-in phase field: `verify: auto`.
- Add `max_attempts` with a hard small limit (pilot: 2).
- Prefer deterministic checks already present in the project.
- On failure, feed the concrete verifier output into one retry.
- If verification still fails, fail the phase and block dependents.
- Store verifier output under the existing run directory.
- Pilot only on `new-feature -> development`; do not enable globally yet.

Non-goals:
- No extra reviewer agent.
- No LangGraph/LangChain dependency.
- No unlimited autonomous retries.
- No new graph semantics.

Exit criteria:
- deterministic verifier can pass/fail;
- one retry is possible;
- retry count contributes to execution-unit metrics;
- downstream phases remain blocked after exhausted verification;
- existing workflow tests remain green.

## Phase 2 — Resume/checkpoints

Add `rorcc workflow resume <run-id|latest>`.

Persist enough information to safely continue:
- workflow and request/classification;
- selected/omitted phases;
- phase state;
- current git SHA/branch;
- verification result and attempt count;
- confirmed human gates.

Do not resume when repository state is incompatible without an explicit human decision.

## Phase 3 — Minimal event trace

Add append-only `.rorcc/runs/<run>/events.jsonl` for significant events only:
- phase/unit start and finish;
- verifier pass/fail;
- retry;
- gate decision;
- workflow stop/resume.

Keep TSV summaries for humans/scripts. JSONL is diagnostic evidence, not a telemetry platform.

## Phase 4 — Run audit

After enough real runs exist, add a read-only audit command that summarizes:
- repeated failures;
- phases/skills with retries;
- unnecessary work;
- verifier effectiveness.

It may propose changes, but must not rewrite RORCC automatically.

## Phase 5 — Documentation consolidation

Perform a repository-wide documentation audit after the runtime work stabilizes, including changes already made in recent RORCC work.

At minimum reconcile:
- `README.md`;
- `docs/README.md`;
- `docs/USER-MANUAL.md`;
- `docs/rorcc-cli.md`;
- integration docs for Cursor, Claude Code and Codex;
- `.ai/README.md`;
- `AGENTS.md` and `CLAUDE.md`;
- orchestration/router docs;
- install/upgrade guidance where behavior changed.

Rules:
- canonical behavior documented once, adapters link to it;
- remove stale instructions instead of preserving historical contradictions;
- examples must match the current CLI;
- documentation changes get their own validation pass.

## Sequence

1. Verification loop.
2. Use it in real work.
3. Resume/checkpoints.
4. Minimal trace.
5. Gather real run evidence.
6. Run audit only if evidence justifies it.
7. Final documentation consolidation.

Each phase should be a separate feature branch/PR and should be merged only after its own tests pass.
