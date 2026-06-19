# MySQL Standards

> MySQL data-layer standard. For PostgreSQL projects, see `.ai/standards/postgresql.md`.

## Schema

- Engine: InnoDB only
- Charset: `utf8mb4`, collation `utf8mb4_unicode_ci` (or project-standard uniform collation)
- Table names: plural, snake_case
- Primary keys: `bigint` auto-increment or UUID per ADR
- `created_at` / `updated_at` on all tables unless documented exception

## Migrations

- Reversible `change` methods when possible; explicit `up`/`down` for complex ops
- Add indexes in same migration as foreign keys
- Large table changes: use online schema change tool or multi-step migration
- Never drop columns in production without deprecation period

## Indexing

- Index all foreign keys
- Composite indexes: most selective column first per query pattern
- Review with `EXPLAIN` for queries > 100ms

## Queries

- No `SELECT *` in hot paths — specify columns
- Paginate large result sets
- Use `find_each` / `in_batches` for bulk operations

## Backups

- Automated daily backups with tested restore procedure
- Point-in-time recovery enabled on RDS production

## References

- Agent: `.ai/agents/rails-architect.yaml` (data modeling, migrations, indexing)
- Skills: `review-db-migrations`, `sql-review`
