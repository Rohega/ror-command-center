---
name: security-audit
description: "Systematically audit application and infrastructure for security vulnerabilities with prioritized remediation. Use when asked for a security review/audit, before a release, or after handling auth, secrets, or PII."
---
# security-audit

## Purpose

Systematically audit application and infrastructure for security vulnerabilities with prioritized remediation.

**Use when:** asked for a security review/audit, before a release, or after handling auth, secrets, or PII.

## Inputs

- Codebase paths or scope (`full`, `api`, `aws`, `auth`)
- `.ai/standards/security.md`
- Recent changes or release branch

## Outputs

- `docs/security/audit-[date].md` with severity-rated findings

## Execution Steps

1. **Scope** — Define audit boundary (app, AWS, integrations).
2. **OWASP scan** — Injection, auth, XSS, CSRF, misconfiguration, etc.
3. **Rails review** — Strong params, mass assignment, authorization gaps.
4. **AWS review** — IAM, S3 policies, secrets, service permissions.
5. **Dependencies** — Known CVEs in Gemfile.lock.
6. **Prioritize** — Critical/High/Medium/Low with remediation steps.
7. **Report** — Sign-off recommendation for release.

## Validation Checklist

- [ ] All OWASP categories considered for scope
- [ ] Every Critical/High has remediation owner
- [ ] No secrets in repository (scan `.env` patterns, credentials)
- [ ] Release blocked if Critical open without waiver
- [ ] Report dated and scoped

## Agent

`security-reviewer`

## Workflow

`.ai/workflows/new-feature.yaml` → phase `review`; `.ai/workflows/aws-deployment.yaml` → `security-review`
