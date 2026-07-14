# QA Test Plan: Docs onboarding hierarchy

**Scope:** Documentation hierarchy / onboarding cleanup (`feature/docs-onboarding-hierarchy`)  
**Author:** QA Engineer (agent)  
**Date:** 2026-07-14

---

## Stories in Scope

| Story ID | Title | Test Type |
|----------|-------|-----------|
| DOC-01 | Instalo Path A y la doc lista lo que copia `install.sh` | Automated (smoke) + Manual |
| DOC-02 | Distingo framework vs ejemplo warehouse | Manual |
| DOC-03 | Contribuyo un skill siguiendo CONTRIBUTING | Manual |
| DOC-04 | Sigo el workflow `new-feature` desde la guía humana | Manual |

## Automated Tests Required

| Story | Spec / script | Scenarios |
|-------|---------------|-----------|
| DOC-01 | `tests/smoke.sh` | `docs/INSTALL.md` mentions each CORE path + `--install-cli`; `install.sh` still lists `AGENTS.md`, `docs/how-to`, `docs/USER-MANUAL.md` |

## Manual Test Cases

### TC-001: Path A install docs
**Preconditions:** Clone on `feature/docs-onboarding-hierarchy`  
**Steps:**
1. Open [docs/README.md](../README.md) → door “Install / use”.
2. Open [INSTALL.md](../INSTALL.md); confirm flags include `--install-cli` and core list includes `AGENTS.md`, `docs/how-to/`, `docs/USER-MANUAL.md`.
3. Run `./install.sh --dry-run /tmp/rorcc-qa-target` and spot-check the same items appear.
**Expected:** Doc and dry-run agree; no contradiction with README landing.  
**Story:** DOC-01  
**Evidence:** smoke suite green (INSTALL sync section).

### TC-002: Example vs framework
**Preconditions:** none  
**Steps:**
1. From [docs/README.md](../README.md) open “EXAMPLE ONLY — warehouse WMS”.
2. Open [specs/warehouse-mvp.md](../specs/warehouse-mvp.md) and the phase-0 runbook; confirm EXAMPLE ONLY banners.
**Expected:** Reader can tell warehouse is not the kit product.  
**Story:** DOC-02

### TC-003: Contribute skill
**Steps:**
1. Read [CONTRIBUTING.md](../../CONTRIBUTING.md) checklist and branching `feature/<ticket>-<slug>`.
2. Confirm Manual §6 points at CONTRIBUTING.
**Expected:** One branching convention; checklist without duplicating the Manual.  
**Story:** DOC-03

### TC-004: Run new-feature workflow
**Steps:**
1. Open [how-to/run-workflows.md](../how-to/run-workflows.md).
2. Confirm `new-feature` phases, Cursor/Claude/`rorcc` invocation, and DoD verification.
3. Confirm link from Manual §4.2 and docs README.
**Expected:** Human can start without reading YAML first; YAML still linked as canonical.  
**Story:** DOC-04

### TC-005: Claude parity
**Steps:**
1. Open [integrations/claude-code.md](../integrations/claude-code.md).
2. Confirm recipes, troubleshooting, and slash table covers ponytail / document-user-guide / whatsapp.
3. Confirm ChatGPT/Gemini/Copilot have **Depth: starter** banners.
**Expected:** Claude user need not jump to cursor.md for basic recipes.  
**Story:** DOC-04 (adjacent)

## Smoke Test Scope (Release)

- [x] `bash tests/smoke.sh` passes (including INSTALL↔CORE sync)
- [x] README landing links to `docs/README.md` and User Manual
- [x] Three doors resolve (install / contribute / example)

## Sign-off Criteria

- [x] All blocking automated tests green (`tests/smoke.sh`)
- [x] Manual cases DOC-01…DOC-04 executed with evidence above
- [x] No open S1/S2 (BLOCKING) defects
- [x] `ponytail-review` on docs diff: Lean already / no new redundant manuals

## Defects

| ID | Sev | Status | Notes |
|----|-----|--------|-------|
| — | — | — | No BLOCKING findings |

## Sign-off

- QA: approved (no BLOCKING) — 2026-07-14  
- Product: deferred to human PR review
