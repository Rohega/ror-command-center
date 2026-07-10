---
name: nginx-puma-review
description: "Review nginx and Puma configuration for production performance, security, and reliability. Use when auditing web/app server config, tuning workers/threads/timeouts, or before a production rollout."
paths:
  - "config/puma.rb"
  - "config/puma/**"
  - "**/nginx*.conf"
  - "config/nginx/**"
---
# nginx-puma-review

## Purpose

Review nginx and Puma configuration for production performance, security, and reliability.

**Use when:** auditing web/app server config, tuning workers/threads/timeouts, or before a production rollout.

## Inputs

- `config/nginx.conf` or site configs, `config/puma.rb`, systemd/capistrano deploy configs
- Expected traffic profile and server resources

## Outputs

- Review report: APPROVED / CONCERNS with configuration recommendations

## Execution Steps

1. **Puma** — Workers, threads, `preload_app!`, socket vs TCP, timeout.
2. **nginx** — Upstream, `proxy_pass`, buffers, timeouts, SSL/TLS.
3. **Unix socket** — Permissions and path consistency with Capistrano.
4. **Static assets** — `try_files`, cache headers, asset pipeline.
5. **Security** — Hide version, limit request size, rate limiting if needed.
6. **Health checks** — Endpoint for load balancer.
7. **Report** — Specific config snippets for fixes.

## Validation Checklist

- [ ] Puma worker count appropriate for CPU/RAM
- [ ] nginx timeouts align with app timeout + buffer
- [ ] SSL configuration modern (TLS 1.2+)
- [ ] No debug endpoints exposed publicly
- [ ] Graceful restart procedure documented

## Agent

`aws-devops-engineer`
