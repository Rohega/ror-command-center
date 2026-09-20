# Module: workflow runner (`rorcc workflow`)

**Audience:** Contributors changing the CLI runner.  
**Humans running a workflow:** [docs/how-to/run-workflows.md](../how-to/run-workflows.md).  
**Rules:** [`.ai/standards/orchestration.md`](../../.ai/standards/orchestration.md).  
**Last updated:** 2026-09-20

## What it does

Reads `.ai/workflows/<name>.yaml`, validates it **without a model**, selects
skills (not redundant agent sessions), enforces `depends_on`, and optionally
runs one-shot completions (`--auto`).

**Boundary:** this is a bash orchestrator. It does not edit the YAML, does not
choose the next phase with an LLM, and does not write application code itself —
it invokes `rorcc skill` / `rorcc agent` per selected unit.

## Code

| File | Responsibility |
|------|----------------|
| `lib/rorcc/workflow.sh` | Parse phases, preflight, `--plan` / run loop, `.rorcc/runs/` |
| `lib/rorcc/router.sh` | Path-based skill/agent selection (`WF_SELECTED` / `WF_OMITTED`) |
| `lib/rorcc/skill.sh` | Skill session; lean cloud prompt when `RORCC_LEAN=1` |
| `lib/rorcc/chat.sh` | Interactive loop or one-shot when `CHAT_ONCE=1` |
| `lib/rorcc/assemble.sh` | `assemble_system` (full) vs `assemble_lean` (workflow cloud) |
| `cli/rorcc` | Dispatches `workflow` to `cmd_workflow` |

Parser field separator is `WF_FS=$'|'` (not tab). Bash `read` collapses
consecutive tabs, which used to drop empty `depends_on` / `gate`.

## Public interface

```text
rorcc workflow <name> [--plan|--auto|--full|--only ids|--skip ids|--local|--cloud]
```

| Exit | When |
|------|------|
| 0 | `--plan` ok, or a run finished without a failed/blocked unit |
| 1 | Workflow file missing, preflight `workflow invalid`, or a phase failed |
| 2 | Unknown flag (`--bogus`) |

## Configuration / ENV

Set by the runner (do not export by hand unless debugging):

| Variable | When | Effect |
|----------|------|--------|
| `RORCC_LEAN=1` | Always during `workflow` | Cloud skills send purpose + `SKILL.md` + named templates, not the full standards dump |
| `RORCC_WORKFLOW_AUTO=1` | `--auto` | `CHAT_ONCE=1` — one model turn per unit |
| `RORCC_BACKEND` | `--local` / `--cloud` | Same as standalone `rorcc skill` |

Run artifacts (after a **real** run, not `--plan`): `.rorcc/runs/<run-id>/`
(`state.tsv`, `metrics.tsv`, `summary.tsv`) — gitignored.

## Commands (verified)

```bash
rorcc workflow new-feature --plan              # 14 declared / 12 selected in this kit
rorcc workflow new-feature --auto --only idea,specification
rorcc workflow does-not-exist                  # exit 1, "workflow not found"
rorcc workflow new-feature --bogus             # exit 2
```

Tests: `tests/smoke.sh` (parser arrays, 14 declared units, preflight, router, `--plan`).

## Error cases

| Output | Cause | Recovery |
|--------|-------|----------|
| `no .ai/ framework found` | CWD has no `.ai/` | `cd` to the clone or installed project |
| `workflow not found` | Name is not one of the four YAML files | Use `new-feature`, `aws-deployment`, `legacy-onboarding`, `production-incident` |
| `workflow invalid` + `error:` lines | Duplicate ids, unknown skill/agent, bad `depends_on` | Fix YAML; **no** LLM was called |
| Phase `blocked` | A dependency is `skipped` / `failed` / `blocked` | Re-run the dependency, or `--only` if that work already exists |
| Skill `omitted: … no matching paths` | Contextual review, files missing | Expected. `--full` to force |

## Do not add here

Parallel CLI workers, LLM routers, tokenizers, SQLite/Redis. See the
`# ponytail:` note in `orchestration.md`.
