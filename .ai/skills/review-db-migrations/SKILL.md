# review-db-migrations

## Purpose

Review Rails database migrations for safety, reversibility, locking risk, and indexing on MySQL.

**Use when:** reviewing a migration before merge/deploy, or when a migration touches large tables.

## Inputs

- Migration file(s) in `db/migrate/`
- `db/schema.rb` for context
- Standards: `.ai/standards/postgresql.md`, `.ai/standards/mysql.md`

## Outputs

- Verdict: APPROVED / CONCERNS / BLOCKED with specific findings

## Execution Steps

1. **Read migration** — `up`/`down` or `change` reversibility.
2. **Table size risk** — Flag add-column-not-null, index on large tables.
3. **Indexes** — Foreign keys indexed; composite index column order.
4. **Data types** — Appropriate limits, null constraints, defaults.
5. **Locking** — Long-running DDL on production tables → recommend pt-osc or multi-step.
6. **Rollback** — Verify `down` restores prior state.
7. **Report** — BLOCKED for data loss or irreversible unsafe ops without plan.

## Validation Checklist

- [ ] Migration is reversible or exception documented
- [ ] New foreign keys have indexes
- [ ] No blocking operations on large tables without mitigation
- [ ] Charset/collation consistent with project
- [ ] DBA sign-off for CONCERNS items before merge

## Agent

`mysql-dba`
