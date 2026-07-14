# ponytail-review — docs onboarding hierarchy

**Diff scope:** `feature/docs-onboarding-hierarchy` (documentation + `tests/smoke.sh` INSTALL sync).  
**Date:** 2026-07-14

## Findings

`docs/USER-MANUAL.md` (refs): delete: duplicate INSTALL link in §9 (same path twice). Fixed — keep one entry.

No other over-engineering: new `docs/README.md` is the required index (not a fourth hub); `docs/modules/README.md` is the promised stub; `run-workflows.md` is one how-to replacing absent human coverage; Claude guide grew to match Cursor rather than inventing a parallel stack; smoke asserts prevent INSTALL drift without a new framework.

**net: -1 lines (duplicate ref).** Lean already for the rest. Ship.

## Out of scope (correctness already covered by QA/smoke)

INSTALL↔CORE sync automated in `tests/smoke.sh`.
