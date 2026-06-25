---
version: 1.0
last-updated: 2026-06-25
owner: "[Craft Engineer]"
domain: "sql-spec-testing"
applies-to: "Any SQL model or transformation that contains complex logic — see trigger list below"
---

# Capability: SQL Spec Testing

## Summary

Whenever a dataset contains complex SQL behaviour — window functions, ranking logic,
custom functions, multi-step transformations, conditional aggregations — a SPEC file
must be created alongside it. The SPEC file documents the intended behaviour in plain
English and contains a self-contained test query that returns rows only when the
behaviour is wrong.

---

## Hard Gate

<HARD-GATE>
Do NOT mark any SQL model or transformation as complete if it contains any trigger (see list below) without a corresponding SPEC file that passes. A complex transformation without a SPEC file is untested logic — it will break silently when data shape or upstream schema changes.
</HARD-GATE>

---

## When a SPEC File Is Required

A SPEC file is mandatory when the model contains **any** of the following:

| Trigger | Examples |
|---|---|
| Window function | `ROW_NUMBER()`, `RANK()`, `DENSE_RANK()`, `NTILE()`, `LAG()`, `LEAD()`, `SUM() OVER`, `AVG() OVER`, `FIRST_VALUE()`, `LAST_VALUE()` |
| Deduplication logic | `ROW_NUMBER() OVER (PARTITION BY ... ORDER BY ...)` used to pick one row per key |
| Conditional aggregation | `SUM(CASE WHEN ... END)`, `COUNT(CASE WHEN ... END)`, `AVG(IF(...))` |
| Custom function or UDF call | Any call to a project-defined function — not a built-in |
| Date or calendar arithmetic | Any logic beyond `DATE_ADD` / `DATE_DIFF` — fiscal calendars, week boundaries, rolling windows |
| Recursive CTE | Any `WITH RECURSIVE` |
| Pivot or unpivot | Turning rows into columns or columns into rows |
| Multi-branch CASE expression | A `CASE WHEN` with 3 or more branches encoding a business rule |
| Multi-step CTE chain | 4 or more CTEs that depend on each other sequentially |

If in doubt, create the SPEC file. The cost of writing it is minutes; the cost of debugging silent wrong output is days.

---

## SPEC File Location and Naming

```
specs/
└── <model_name>/
    └── <behaviour_slug>.spec.sql
```

**Rules:**
- One SPEC file per distinct behaviour, not per model. A model with two window functions gets two SPEC files.
- `<model_name>` matches the model file name without extension: `fact_orders`, `dim_customers`
- `<behaviour_slug>` describes the behaviour in kebab-case: `customer-running-total`, `latest-address-dedup`, `fiscal-week-assignment`

**Examples:**

| Model | Behaviour | SPEC file path |
|---|---|---|
| `fact_orders` | Running total per customer | `specs/fact_orders/customer-running-total.spec.sql` |
| `dim_customers` | Dedup to latest address per customer | `specs/dim_customers/latest-address-dedup.spec.sql` |
| `fct_sessions` | Session ranking by recency | `specs/fct_sessions/session-recency-rank.spec.sql` |
| `mart_revenue` | Conditional aggregation by payment type | `specs/mart_revenue/revenue-by-payment-type.spec.sql` |

---

## SPEC File Structure

Every SPEC file follows this exact structure: a header comment block that documents the
behaviour, followed by a self-contained test query.

```sql
-- SPEC: <behaviour name — matches the file slug in plain English>
-- MODEL: <model file name>
-- TRIGGER: <which trigger from the list above caused this spec>
--
-- BEHAVIOUR:
--   <Plain English. What does this logic do? What question does it answer?>
--   <Write it so a new team member understands without reading the SQL.>
--
-- INPUT:
--   <Describe the input rows or show a small representative example.>
--   <Include the columns and values that matter for this behaviour.>
--
-- EXPECTED OUTPUT:
--   <Describe what the query must produce for the input above.>
--   <Show the expected rows explicitly.>
--
-- EDGE CASES:
--   - <Edge case 1: e.g. customer with only one order — running total equals order total>
--   - <Edge case 2: e.g. NULL amount — excluded from running total, not treated as zero>
--   - <Edge case 3: e.g. two orders on the same timestamp — tie-breaking rule applies>
--
-- FAILS WHEN: this query returns rows. Empty result = behaviour is correct.

WITH input_fixture AS (
    -- Small, controlled dataset that exercises the behaviour and all edge cases above.
    -- Use literal VALUES — do not reference production tables.
    SELECT ...
),

actual AS (
    -- The logic under test, copied verbatim from the model and applied to input_fixture.
    -- Replace the model's source table reference with input_fixture.
    SELECT ...
),

expected AS (
    -- The exact rows that must come out for the behaviour to be correct.
    -- Use literal VALUES — hand-write the expected result.
    SELECT ...
),

mismatches AS (
    SELECT
        actual.*,
        expected.<key_column> AS expected_key,
        expected.<value_column> AS expected_value
    FROM actual
    FULL OUTER JOIN expected
        ON actual.<key_column> = expected.<key_column>
    WHERE actual.<value_column> != expected.<value_column>
       OR actual.<key_column> IS NULL   -- row in expected but missing from actual
       OR expected.<key_column> IS NULL -- row in actual but not expected
)

SELECT * FROM mismatches;
-- An empty result means the behaviour is correct.
-- Any returned row is a test failure with the full diff visible.
```

---

## Worked Examples

### Example 1 — Window function: running total per customer

```sql
-- SPEC: customer running total
-- MODEL: fact_orders
-- TRIGGER: window function — SUM() OVER (PARTITION BY customer_id ORDER BY order_date)
--
-- BEHAVIOUR:
--   For each order, compute the cumulative sum of order_total for that customer,
--   ordered by order_date ascending. The running total includes the current row.
--
-- INPUT:
--   customer_id | order_id | order_date | order_total
--   1           | A        | 2026-01-01 | 100
--   1           | B        | 2026-01-03 | 200
--   2           | C        | 2026-01-02 | 50
--
-- EXPECTED OUTPUT:
--   customer_id | order_id | running_total
--   1           | A        | 100
--   1           | B        | 300
--   2           | C        | 50
--
-- EDGE CASES:
--   - Customer with one order: running total equals order_total
--   - Two orders on the same date: order within tie is deterministic (order by order_id)
--   - NULL order_total: excluded, not treated as zero (handled upstream)
--
-- FAILS WHEN: this query returns rows. Empty result = behaviour is correct.

WITH input_fixture AS (
    SELECT 1 AS customer_id, 'A' AS order_id, DATE '2026-01-01' AS order_date, 100.0 AS order_total
    UNION ALL
    SELECT 1, 'B', DATE '2026-01-03', 200.0
    UNION ALL
    SELECT 2, 'C', DATE '2026-01-02', 50.0
),

actual AS (
    SELECT
        customer_id,
        order_id,
        SUM(order_total) OVER (
            PARTITION BY customer_id
            ORDER BY order_date ASC, order_id ASC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_total
    FROM input_fixture
),

expected AS (
    SELECT 1 AS customer_id, 'A' AS order_id, 100.0 AS running_total
    UNION ALL
    SELECT 1, 'B', 300.0
    UNION ALL
    SELECT 2, 'C', 50.0
),

mismatches AS (
    SELECT
        actual.customer_id,
        actual.order_id,
        actual.running_total AS actual_running_total,
        expected.running_total AS expected_running_total
    FROM actual
    FULL OUTER JOIN expected
        ON actual.customer_id = expected.customer_id
        AND actual.order_id = expected.order_id
    WHERE actual.running_total != expected.running_total
       OR actual.order_id IS NULL
       OR expected.order_id IS NULL
)

SELECT * FROM mismatches;
```

---

### Example 2 — Deduplication: latest address per customer

```sql
-- SPEC: latest address dedup
-- MODEL: dim_customers
-- TRIGGER: deduplication — ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY updated_at DESC)
--
-- BEHAVIOUR:
--   For each customer, keep only the most recently updated address record.
--   When two records share the same updated_at, keep the one with the higher address_id.
--
-- INPUT:
--   customer_id | address_id | updated_at          | city
--   1           | 10         | 2026-01-01 09:00:00 | London
--   1           | 11         | 2026-03-15 14:00:00 | Paris
--   2           | 12         | 2026-02-01 00:00:00 | Berlin
--   2           | 13         | 2026-02-01 00:00:00 | Berlin  ← same timestamp, higher id wins
--
-- EXPECTED OUTPUT:
--   customer_id | address_id | city
--   1           | 11         | Paris
--   2           | 13         | Berlin
--
-- EDGE CASES:
--   - Customer with one address: that address is kept
--   - Two addresses with identical updated_at: higher address_id wins (deterministic tie-break)
--   - NULL updated_at: treated as oldest (NULLS LAST in ORDER BY)
--
-- FAILS WHEN: this query returns rows. Empty result = behaviour is correct.

WITH input_fixture AS (
    SELECT 1 AS customer_id, 10 AS address_id, TIMESTAMP '2026-01-01 09:00:00' AS updated_at, 'London' AS city
    UNION ALL
    SELECT 1, 11, TIMESTAMP '2026-03-15 14:00:00', 'Paris'
    UNION ALL
    SELECT 2, 12, TIMESTAMP '2026-02-01 00:00:00', 'Berlin'
    UNION ALL
    SELECT 2, 13, TIMESTAMP '2026-02-01 00:00:00', 'Berlin'
),

ranked AS (
    SELECT
        customer_id,
        address_id,
        city,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY updated_at DESC NULLS LAST, address_id DESC
        ) AS rn
    FROM input_fixture
),

actual AS (
    SELECT customer_id, address_id, city
    FROM ranked
    WHERE rn = 1
),

expected AS (
    SELECT 1 AS customer_id, 11 AS address_id, 'Paris' AS city
    UNION ALL
    SELECT 2, 13, 'Berlin'
),

mismatches AS (
    SELECT
        actual.customer_id,
        actual.address_id AS actual_address_id,
        expected.address_id AS expected_address_id,
        actual.city AS actual_city,
        expected.city AS expected_city
    FROM actual
    FULL OUTER JOIN expected ON actual.customer_id = expected.customer_id
    WHERE actual.address_id != expected.address_id
       OR actual.city != expected.city
       OR actual.customer_id IS NULL
       OR expected.customer_id IS NULL
)

SELECT * FROM mismatches;
```

---

## Running SPEC Files

SPEC files are plain SQL — run them directly against the warehouse or in a test harness.

```bash
# BigQuery (bq CLI)
bq query --use_legacy_sql=false < specs/fact_orders/customer-running-total.spec.sql

# Snowflake (SnowSQL)
snowsql -q "$(cat specs/fact_orders/customer-running-total.spec.sql)"

# DuckDB (for local testing with fixture data)
duckdb -c "$(cat specs/fact_orders/customer-running-total.spec.sql)"

# dbt (if the spec is placed in tests/ as a singular test)
dbt test --select fact_orders
```

A SPEC that returns zero rows passes. Any returned row is a failure and shows the exact
diff between actual and expected output.

---

## Completion Gate

Before marking any SQL model done, for each trigger present in the model:

- [ ] SPEC file exists at `specs/<model_name>/<behaviour-slug>.spec.sql`
- [ ] Header block is complete: BEHAVIOUR, INPUT, EXPECTED OUTPUT, EDGE CASES all filled in
- [ ] Input fixture uses literal `VALUES` — no references to production tables
- [ ] Expected output is hand-written literal rows — not derived from the logic under test
- [ ] At least two edge cases are documented and covered by the fixture
- [ ] SPEC query returns zero rows when run against the warehouse
- [ ] SPEC file is committed in the same PR as the model it tests
