# PostgreSQL Standards

> PostgreSQL data-layer standard. For MySQL projects, see `.ai/standards/mysql.md`.

## Schema

- Table names: plural, snake_case
- Primary keys: `bigint` identity or UUID (`gen_random_uuid()`) per ADR
- `created_at` / `updated_at` (`timestamptz`) on all tables unless documented exception
- Prefer `timestamptz` over `timestamp`; store UTC
- Use native types: `jsonb` (not `json`), `enum`/`citext`/`inet` where they add value
- Enforce data integrity with `NOT NULL`, `CHECK`, and unique constraints — not just app validations

## Migrations

- Reversible `change` methods when possible; explicit `up`/`down` for complex ops
- Add indexes `algorithm: :concurrently` on large tables, with `disable_ddl_transaction!`
- Add foreign keys with `validate: false` then validate in a separate step on large tables
- Never drop columns in production without a deprecation period (use `ignored_columns` first)
- Set `lock_timeout` and `statement_timeout` for risky DDL

## Indexing

- Index all foreign keys
- Use partial indexes for filtered queries (e.g. `WHERE deleted_at IS NULL`)
- Use GIN indexes for `jsonb` and full-text search
- Composite indexes: most selective column first per query pattern
- Review with `EXPLAIN (ANALYZE, BUFFERS)` for queries > 100ms

## Queries

- No `SELECT *` in hot paths — specify columns
- Paginate large result sets (keyset pagination for deep pages)
- Use `find_each` / `in_batches` for bulk operations
- Watch for N+1; use `includes`/`preload`/`eager_load` deliberately

## Operations

- Connection pooling via PgBouncer for high-concurrency apps
- Automated daily backups with tested restore procedure
- Point-in-time recovery enabled on RDS production
- Monitor bloat, long-running transactions, and replication lag

## References

- Agent: `.ai/agents/rails-architect.yaml` (data modeling, migrations, indexing)
- Skills: `review-db-migrations`, `sql-review`
