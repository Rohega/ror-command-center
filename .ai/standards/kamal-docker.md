# Containerized Deployment Standards (Docker + Kamal)

> Deployment standard for Docker images and Kamal. For traditional server deploys, see
> `capistrano-review`. Choose one deploy strategy per project via ADR.

## Docker Images

- Multi-stage builds: separate build (gems/assets) from the slim runtime image
- Pin the Ruby base image to a specific patch version; rebuild for security updates
- Run as a non-root user; set `WORKDIR`, drop build toolchain from the final stage
- Precompile assets at build time; bundle without `development`/`test` groups
- Add a `HEALTHCHECK`; expose only required ports
- Never bake secrets into images — inject at runtime

## Kamal

- Define apps, roles (web/worker), and accessories (Postgres/MySQL, Redis) in `deploy.yml`
- Manage secrets via `.kamal/secrets` + a secrets manager — never commit them
- Use the built-in `kamal-proxy` (or Traefik) for zero-downtime rollouts and TLS
- Configure health checks so bad releases never take traffic
- Tag images by git SHA; keep deploys reproducible and rollback-able (`kamal rollback`)
- Run DB migrations as a release/pre-deploy step, gated and idempotent

## AWS Integration

- Push images to ECR; least-privilege IAM for the deploy role
- Run on EC2/ECS per architecture; centralize logs (CloudWatch) and metrics
- Store env/secrets in SSM Parameter Store or Secrets Manager

## Operations

- Every deploy plan includes rollback steps and an RTO target
- Monitor container health, restarts, and resource limits
- Keep staging at parity with production

## Anti-patterns

- `latest` tags in production
- Secrets in Dockerfiles, images, or committed config
- Migrations run ad hoc instead of via the deploy pipeline

## References

- Agent: `.ai/agents/aws-devops-engineer.yaml`
- Related: `.ai/standards/aws-infrastructure.md`, `.ai/skills/capistrano-review/SKILL.md`
