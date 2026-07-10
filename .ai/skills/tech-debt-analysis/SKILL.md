---
name: tech-debt-analysis
description: "Scan and catalog technical debt, prioritize repayment, and maintain a debt register. Use when assessing codebase health, planning refactors, or building a tech-debt backlog."
---
# tech-debt-analysis

## Purpose

Scan and catalog technical debt, prioritize repayment, and maintain a debt register.

**Use when:** assessing codebase health, planning refactors, or building a tech-debt backlog.

## Inputs

- Codebase (optional path scope)
- Existing debt register if present: `docs/tech-debt/register.md`
- Argument: `scan` | `add` | `prioritize` | `report`

## Outputs

- Updated debt register and summary report

## Execution Steps

1. **Parse mode** — scan, add manual entry, prioritize, or report.
2. **Scan (if scan)** — TODO/FIXME/HACK, large files, missing tests, ADR drift.
3. **Categorize** — Architecture, code quality, test, documentation, infrastructure.
4. **Score** — Impact × effort; align with sprint capacity.
5. **Register** — Add entries with owner and target sprint optional.
6. **Report** — Top items, trends, recommended repayment schedule.
7. **Approve** — Show register changes before writing.

## Validation Checklist

- [ ] Each entry has category, description, and severity
- [ ] Critical debt linked to production risk
- [ ] Repayment items feasible within team capacity
- [ ] Scan date recorded on report
- [ ] No duplicate entries for same issue

## Agent

`code-reviewer` (analysis); `rails-architect` (architecture debt)
