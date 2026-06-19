# Authentication Standards (Devise)

> Authentication standard for Rails apps using Devise. Authorization rules live in
> `.ai/standards/security.md`.

## Setup

- Single `User` model unless an ADR justifies multiple resources (e.g. `AdminUser`)
- Enable only the modules you need: `database_authenticatable`, `registerable`,
  `recoverable`, `rememberable`, `validatable`, `confirmable`, `lockable`, `trackable`,
  `timeoutable`
- Use `confirmable` for email verification and `lockable` for brute-force protection
- Configure `config.pepper` and a strong `stretches` value; keep secrets out of the repo

## Sessions & Tokens

- Web: cookie sessions with `secure`, `httponly`, `samesite` set
- APIs: use `devise-jwt` or a token strategy — never reuse the session cookie for stateless APIs
- Set `timeout_in` for sensitive applications; force re-auth for high-risk actions

## Passwords & MFA

- Enforce minimum length and complexity per `.ai/standards/security.md`
- Add 2FA (`devise-two-factor`) for admin and privileged roles
- Rate-limit login, password reset, and confirmation endpoints (Rack::Attack)

## Customization

- Override controllers under `app/controllers/users/` only when needed; keep logic thin
- Put post-auth side effects in Service Objects or jobs, not controllers
- Customize views for accessibility and consistent UX (see `.ai/standards/ux-accessibility.md`)

## Anti-patterns

- Rolling your own password hashing or reset flow
- Storing tokens or reset secrets in plain text or logs
- Skipping authorization because the user is "logged in" — authenticate ≠ authorize

## References

- Agents: `.ai/agents/backend-rails-developer.yaml`, `.ai/agents/security-reviewer.yaml`
- Related: `.ai/standards/security.md`, `.ai/standards/api-design.md`
