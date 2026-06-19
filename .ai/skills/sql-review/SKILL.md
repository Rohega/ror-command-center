# sql-review

## Purpose

Review SQL and ActiveRecord queries for correctness, performance, and index usage.

## Inputs

- Query code, slow query log excerpt, or EXPLAIN output
- Relevant schema from `db/schema.rb`
- Standards: `.ai/standards/postgresql.md`, `.ai/standards/mysql.md`

## Outputs

- SQL review report with optimization recommendations

## Execution Steps

1. **Capture query** — Raw SQL or AR equivalent with bindings noted.
2. **EXPLAIN** — Analyze access type, rows examined, index usage.
3. **N+1 check** — If AR, trace association loading.
4. **Index recommendations** — New or composite indexes if justified.
5. **Rewrite suggestions** — Subqueries, joins, limits, batching.
6. **Report** — Before/after estimated impact when possible.

## Validation Checklist

- [ ] EXPLAIN reviewed for production-representative data volume
- [ ] No full table scans on large tables without justification
- [ ] Index recommendations include migration sketch
- [ ] Query returns correct results (logic verified)
- [ ] Findings prioritized by execution frequency × cost

## Agent

`mysql-dba`
