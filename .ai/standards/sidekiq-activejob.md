# Background Processing Standards (ActiveJob + Sidekiq)

> Async work standard. Prefer ActiveJob as the interface; Sidekiq as the production adapter.

## When to Use Background Jobs

- Any I/O outside the request cycle: email, webhooks, third-party APIs, OCR, file processing
- Work > ~200ms that does not need a synchronous response
- Fan-out and batch operations

## Conventions

- Define jobs as `ApplicationJob` subclasses in `app/jobs/`
- Keep `perform` thin — delegate to a Service Object; jobs orchestrate, services do work
- Pass identifiers (IDs), never whole ActiveRecord objects, as arguments (GlobalID excepted)
- Make jobs **idempotent** — they may run more than once
- Set explicit queues by latency class: `critical`, `default`, `low`, `mailers`

## Reliability

- Configure retries with backoff; define a discard/dead-set policy for poison jobs
- Use unique-job locks (e.g. `sidekiq-unique-jobs`) to avoid duplicate enqueues where needed
- Wrap external calls with timeouts and circuit breakers
- Record job outcomes for auditable workflows (status column or audit log)

## Scheduling

- Use `sidekiq-cron` or `solid_queue` recurring tasks for periodic work — never `sleep` loops
- Document every scheduled job (cadence, owner, side effects)

## Operations

- Run Sidekiq under systemd/Docker with `-c` concurrency tuned to DB pool size
- Protect the Sidekiq Web UI behind authentication and authorization
- Monitor queue latency, retry set, and dead set; alert on growth
- Redis: enable persistence (AOF) and a tested restore procedure

## Security

- Never log secrets or PII in job arguments (visible in Redis/Web UI)
- Authorize work inside the job; do not trust enqueued data blindly

## References

- Agents: `.ai/agents/backend-rails-developer.yaml`, `.ai/agents/rails-architect.yaml`
- Related: `.ai/standards/development.md`, `.ai/standards/security.md`
