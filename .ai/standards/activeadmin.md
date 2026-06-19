# Admin Standards (ActiveAdmin)

> Standard for internal admin/back-office interfaces built with ActiveAdmin.

## When to Use

- Internal CRUD, operations, and support tooling — not customer-facing UX
- For rich customer UX, use the frontend stack (`.ai/standards/frontend.md`) instead

## Security

- ActiveAdmin authentication is separate from end-user auth — use a dedicated `AdminUser`
- Enforce authorization with a policy adapter (Pundit/CanCanCan); deny by default
- Scope every resource to what the admin is allowed to see (multi-tenant safety)
- Audit privileged actions (e.g. `paper_trail`); log who changed what and when
- Protect destructive batch actions behind confirmation and role checks

## Conventions

- Keep `app/admin/*.rb` registrations declarative; move logic to Service Objects
- Use `permit_params` explicitly — never permit all attributes
- Prefer scopes, filters, and batch actions over custom controllers
- Avoid N+1 in index/show with `includes`

## Performance

- Paginate and limit default index columns on large tables
- Offload heavy exports and reports to background jobs

## Anti-patterns

- Exposing ActiveAdmin to customers or the public internet without network controls
- Business logic embedded in admin DSL blocks
- Unscoped resources leaking cross-tenant data

## References

- Agents: `.ai/agents/backend-rails-developer.yaml`, `.ai/agents/security-reviewer.yaml`
- Related: `.ai/standards/security.md`, `.ai/standards/development.md`
