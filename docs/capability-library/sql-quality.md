---
version: 1.1
last-updated: 2026-06-25
owner: "[Craft Engineer]"
domain: "sql-quality"
applies-to: "Every SQL file, data pipeline transformation, and table orchestration created in this project"
---

# Capability: SQL Quality

## Summary

Every SQL transformation must pass a SQLFluff lint check and a performance review before it is committed. This capability defines the exact commands to run, the rules being enforced, and the performance checklist that cannot be automated.

---

## Hard Gate

<HARD-GATE>
Do NOT mark any SQL transformation, data pipeline step, or table orchestration as complete until the SQLFluff lint command below exits with zero violations AND every item in the Performance Checklist is verified. This gate applies to every SQL file regardless of size.
</HARD-GATE>

---

## Tool: SQLFluff

SQLFluff is the SQL linter for this project. It is installed once and run on every SQL file that is created or modified.

### Installation

```bash
pip install sqlfluff

# If the project uses dbt with Jinja templating:
pip install sqlfluff sqlfluff-templater-dbt
```

### Commands — run these every time a SQL file is created or changed

```bash
# Lint a single file — shows all violations with rule IDs and line numbers
sqlfluff lint path/to/model.sql

# Lint all SQL files in a directory
sqlfluff lint models/

# Auto-fix violations that SQLFluff can correct automatically
sqlfluff fix path/to/model.sql

# Auto-fix all SQL files in a directory
sqlfluff fix models/

# Lint and show a summary of rule violations across the whole project
sqlfluff lint . --format github-annotation
```

The config file at `.sqlfluff` (repo root) sets the dialect, indentation rules, and capitalisation policy. **Do not pass `--dialect` on the command line if `.sqlfluff` already declares it** — the file takes precedence and avoids dialect mismatches between developers.

### Changing the dialect

The repo ships with `dialect = bigquery` in `.sqlfluff`. If the project uses a different warehouse, update the dialect in `.sqlfluff` at inception:

| Warehouse | Dialect value |
|---|---|
| BigQuery | `bigquery` |
| Snowflake | `snowflake` |
| Databricks / Spark | `sparksql` |
| Redshift | `redshift` |
| PostgreSQL | `postgres` |
| DuckDB | `duckdb` |
| Trino / Starburst | `trino` |
| Azure Synapse / SQL Server | `tsql` |

### dbt projects

If the project uses dbt, set `templater = dbt` in `.sqlfluff` and install the dbt templater:

```bash
pip install sqlfluff-templater-dbt
```

Then lint via:

```bash
sqlfluff lint models/ --templater dbt
```

---

## Lint Rules in Force

These rules are configured in `.sqlfluff` and enforced on every lint run. Zero violations is the only passing state.

| Rule ID | What SQLFluff checks | Rationale |
|---|---|---|
| `capitalisation.keywords` | `SELECT`, `FROM`, `WHERE`, `JOIN`, `GROUP BY`, `ORDER BY`, `WITH` must be UPPER CASE | Consistency; auto-fixable |
| `capitalisation.identifiers` | Column names and table aliases must be lowercase | Enforces `snake_case` naming |
| `capitalisation.functions` | Built-in functions (`COUNT`, `SUM`, `COALESCE`) must be UPPER CASE | Consistency with keywords |
| `capitalisation.literals` | `TRUE`, `FALSE`, `NULL` must be UPPER CASE | Consistency |
| `aliasing.table` | `AS` keyword required for table aliases — `FROM t AS orders`, not `FROM t orders` | Readability |
| `aliasing.column` | `AS` keyword required for column aliases | Readability |
| `ambiguous.column_references` | `GROUP BY` and `ORDER BY` must use column names, not positional integers | Positional refs break on column reorder |
| `structure.columns` | No `SELECT *` in any production query | Schema drift silently breaks downstream |

### Rules not covered by SQLFluff (manual review required)

SQLFluff checks syntax and style. It does not check query logic or cost. The following must be reviewed by eye — see the Performance Checklist below.

---

## Performance Review Checklist

Complete this checklist manually for every new or modified transformation. It cannot be automated.

### Filter-First Rule (most critical)

- [ ] **Filters (`WHERE` clauses) are applied before any joins, window functions, or aggregations.** Transforming an unfiltered full table then filtering is prohibited.

```sql
-- WRONG: join runs on millions of unfiltered rows
SELECT t.order_id, t.amount, d.department_name
FROM transactions AS t
JOIN departments AS d ON t.dept_id = d.id
WHERE t.created_at >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY);

-- CORRECT: filter in a CTE first, join on the smaller set
WITH recent_transactions AS (
    SELECT order_id, amount, dept_id
    FROM transactions
    WHERE created_at >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
)
SELECT rt.order_id, rt.amount, d.department_name
FROM recent_transactions AS rt
JOIN departments AS d ON rt.dept_id = d.id;
```

### Join Complexity

- [ ] Every `JOIN` has an explicit `ON` condition — no implicit cross joins
- [ ] Intentional cross joins are commented with the reason and expected output row count
- [ ] The same source table is not joined more than once — use a CTE instead

### Partition and Cluster Pruning

- [ ] Queries against partitioned tables filter on the partition column in `WHERE`
- [ ] Functions are not applied to partition columns in `WHERE` — use range comparisons

```sql
-- WRONG: DATE() wrapping prevents partition pruning
WHERE DATE(created_at) = '2026-01-01'

-- CORRECT: range comparison on the raw column
WHERE created_at >= '2026-01-01' AND created_at < '2026-01-02'
```

### Aggregation and Window Functions

- [ ] `GROUP BY` runs on the smallest possible dataset — filters precede aggregation
- [ ] Window functions (`OVER (PARTITION BY ...)`) do not appear in `WHERE` — they live in a CTE
- [ ] Window functions partitioning by a high-cardinality column are flagged for review

### Subquery and CTE Complexity

- [ ] CTEs preferred over nested subqueries when a dataset is referenced more than once
- [ ] No CTE nesting deeper than 3 levels without a documented reason
- [ ] Recursive CTEs include a row-count guard or `LIMIT`

### Large Table Operations

- [ ] Tables larger than 1 GB use an incremental strategy — documented in the CTE or with a comment
- [ ] `ORDER BY` without `LIMIT` is not used inside subqueries or CTEs

---

## Anti-Patterns Reference

| Anti-Pattern | Why It's Blocked | Correct Pattern |
|---|---|---|
| `SELECT *` in production | Schema changes silently break downstream | List every column explicitly |
| Transform then filter | Wastes compute on rows that are discarded | Filter first in a CTE, then transform |
| Function on partition column in `WHERE` | Disables partition pruning, causes full scans | Use range comparisons on the raw column |
| Implicit cross join | Produces Cartesian product silently | Always use explicit `JOIN ... ON ...` |
| `DISTINCT` to fix duplicates | Hides upstream data quality problems | Investigate and fix the source of duplicates |
| `ORDER BY` in CTE | Ordering is undefined in CTEs in most engines | Remove — order only at the final `SELECT` |
| Non-incremental scan of large tables | Cost and latency scale with full table size | Add a time-window or change-data filter |
| Nested subqueries deeper than 3 levels | Unreadable and un-debuggable | Flatten into named CTEs |

---

## Completion Gate

Before marking any SQL task done, run the following and include the output as evidence:

```bash
sqlfluff lint <path>
```

Then verify every item:

- [ ] `sqlfluff lint` exits with **zero violations** — output attached
- [ ] Filter-First Rule verified — `WHERE` clauses precede all joins and aggregations
- [ ] No `SELECT *` in any production-facing query
- [ ] Partition pruning verified for any query against a partitioned table
- [ ] No cross joins without a documented intent comment
- [ ] Large-table incremental strategy documented if any source exceeds 1 GB
- [ ] If the model contains complex logic (window functions, dedup, UDFs, conditional aggregation, date arithmetic, pivot, multi-branch CASE) — SPEC file created and passing. See `docs/capability-library/sql-spec-testing.md`.
