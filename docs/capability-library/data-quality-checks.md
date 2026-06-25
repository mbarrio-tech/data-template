---
version: 1.1
last-updated: 2026-06-25
owner: "[Craft Engineer]"
domain: "data-quality-checks"
applies-to: "Every table produced by the pipeline — models in DBT, Dataform, or any orchestration layer"
---

# Capability: Data Quality Checks

## Summary

Every table created or modified by the pipeline must have a defined and passing set of quality tests before it is considered production-ready. This capability defines which tests are mandatory, which are conditional, and how to implement them in both DBT and Dataform.

---

## Hard Gate

<HARD-GATE>
Do NOT mark any table, model, or pipeline step as complete until the Quality Test Checklist below is fully implemented and all tests pass. A table without tests is not done — it is untested code waiting to corrupt downstream data.
</HARD-GATE>

---

## dbt Project Prerequisites

Before writing any tests, ensure these two files exist at the repo root.

**`packages.yml`** — declares `dbt_utils` for any macro-based tests:

```yaml
packages:
  - package: dbt-labs/dbt_utils
    version: "1.3.0"
```

After adding or changing `packages.yml`, run:

```bash
dbt deps
```

**Preferred approach for row count and business logic tests:** use plain singular SQL files in `tests/` rather than `dbt_utils` macros. Singular tests have no package dependency, compile in every dbt version, and are easier to read. Reserve `dbt_utils` for tests that genuinely need its macros (e.g. `recency`, `equality`).

---

## Table Tier Classification

Classify every table before determining which tests apply.

| Tier | Definition | Examples |
|---|---|---|
| **Critical** | Directly feeds a client-facing report, dashboard, or downstream system | `fact_orders`, `dim_customers`, finance aggregates |
| **Standard** | Internal pipeline model used by other models | Staging tables, intermediate CTEs materialised as views |
| **Raw / Staging** | Source extract or light rename — not aggregated | `raw_events`, `stg_salesforce_accounts` |

Tests escalate with tier. Critical tables carry the strictest requirements.

---

## Mandatory Tests — All Tiers

Every table must have these tests regardless of tier. No exceptions.

### 1. Primary Key Integrity

- **Not null** on the primary key column(s)
- **Unique** on the primary key column(s)

```yaml
# DBT (schema.yml)
models:
  - name: fact_orders
    columns:
      - name: order_id
        tests:
          - not_null
          - unique
```

```js
// Dataform (definitions/fact_orders.sqlx)
config {
  assertions: {
    nonNull: ["order_id"],
    uniqueKey: ["order_id"]
  }
}
```

### 2. Accepted Values for Categorical Columns

Every column with a fixed set of valid values must have an `accepted_values` test. When a new category appears that is not in the accepted list, the test fails immediately rather than silently propagating bad data.

```yaml
# DBT
- name: status
  tests:
    - accepted_values:
        values: ['pending', 'processing', 'shipped', 'delivered', 'cancelled']
```

```js
// Dataform — custom assertion
assert("fact_orders_valid_status").query(`
  SELECT * FROM ${ref("fact_orders")}
  WHERE status NOT IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled')
`)
```

### 3. Referential Integrity

Every foreign key must have a relationship test to its parent table.

```yaml
# DBT
- name: customer_id
  tests:
    - relationships:
        to: ref('dim_customers')
        field: customer_id
```

```js
// Dataform — custom assertion
assert("fact_orders_fk_customer").query(`
  SELECT fo.order_id
  FROM ${ref("fact_orders")} fo
  LEFT JOIN ${ref("dim_customers")} dc ON fo.customer_id = dc.customer_id
  WHERE dc.customer_id IS NULL
`)
```

---

## Additional Tests — Critical and Standard Tiers

Apply these tests to all Critical and Standard tier tables.

### 4. Row Count Anomaly Detection

The table must have a test that fails when the row count drops to zero. A zero-row table that was non-empty yesterday is always a pipeline failure, never a valid state.

Implement this as a **singular test** — a plain SQL file in `tests/` that returns rows only on failure. This requires no external package and works in every dbt version.

```sql
-- tests/<table>_not_empty.sql
-- Returns 1 row (failure) when the table has zero rows.
SELECT 1 AS failure
FROM {{ ref('fact_orders') }}
HAVING COUNT(*) = 0
```

If the project already uses `dbt_utils` (declared in `packages.yml`), the `expression_is_true` macro is an equivalent alternative:

```yaml
# DBT — requires dbt-labs/dbt_utils in packages.yml
- name: fact_orders
  tests:
    - dbt_utils.expression_is_true:
        expression: "count(*) > 0"
```

```js
// Dataform — custom assertion
assert("fact_orders_not_empty").query(`
  SELECT COUNT(*) AS row_count
  FROM ${ref("fact_orders")}
  HAVING COUNT(*) = 0
`)
```

### 5. Not Null on Business-Critical Columns

Beyond the primary key, identify columns that must never be null in a valid row (e.g. `amount`, `created_at`, `event_type`). Apply `not_null` to each.

Document the rationale: if a column is allowed to be null, write a comment explaining when and why. Unexplained nulls in critical columns are a data quality failure.

### 6. Freshness Assertion

Critical and Standard tables that are loaded on a schedule must have a freshness assertion: if the most recent record is older than `N` hours/days, the pipeline is considered stale.

```yaml
# DBT source freshness
sources:
  - name: raw
    tables:
      - name: orders
        loaded_at_field: _etl_loaded_at
        freshness:
          warn_after: {count: 6, period: hour}
          error_after: {count: 24, period: hour}
```

```js
// Dataform — custom assertion
assert("fact_orders_freshness").query(`
  SELECT MAX(created_at) AS latest_record
  FROM ${ref("fact_orders")}
  HAVING MAX(created_at) < TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR)
`)
```

---

## Additional Tests — Critical Tier Only

### 7. Business Logic Assertion

Critical tables must have at least one custom test that encodes a known business rule. Generic structural tests (not_null, unique) are necessary but not sufficient.

Examples:
- `order_total >= 0` — no negative order totals
- `delivered_at >= shipped_at` — delivery cannot precede shipment
- `refund_amount <= order_total` — refund cannot exceed original amount

Write the assertion as a query that returns rows when the rule is violated. A non-empty result is a test failure.

```js
// Dataform
assert("fact_orders_no_negative_total").query(`
  SELECT order_id, order_total
  FROM ${ref("fact_orders")}
  WHERE order_total < 0
`)
```

### 8. Column Coverage Documentation

Every column in a Critical table must be documented with:
- A plain-English description
- Its null policy (never null / nullable — reason)
- Its accepted values or range (if applicable)

This is enforced at code review. A Critical table model without column descriptions does not pass the gate.

---

## Test Naming Convention

Test names must be descriptive enough to diagnose the failure without reading the test body.

| Pattern | Example |
|---|---|
| `<table>_pk_not_null` | `fact_orders_pk_not_null` |
| `<table>_pk_unique` | `fact_orders_pk_unique` |
| `<table>_fk_<parent>` | `fact_orders_fk_customer` |
| `<table>_<column>_accepted_values` | `fact_orders_status_accepted_values` |
| `<table>_not_empty` | `fact_orders_not_empty` |
| `<table>_freshness` | `fact_orders_freshness` |
| `<table>_<rule>` | `fact_orders_no_negative_total` |

---

## Completion Gate

Before marking any table or model as done:

- [ ] Table tier classified (Critical / Standard / Raw)
- [ ] Not null + unique tests on all primary key columns
- [ ] Accepted values tests on all categorical columns
- [ ] Referential integrity tests on all foreign key columns
- [ ] Row count anomaly assertion implemented as a singular test in `tests/<table>_not_empty.sql` (Critical and Standard)
- [ ] Freshness assertion implemented if table is schedule-loaded (Critical and Standard)
- [ ] Business logic assertions implemented as singular tests in `tests/` with at least one domain rule (Critical only)
- [ ] All columns in Critical tables are documented with description and null policy
- [ ] All tests pass locally before committing: `dbt test -s <model>` or Dataform equivalent
- [ ] Test names follow the naming convention above
- [ ] If `dbt_utils` macros are used: `packages.yml` declares `dbt-labs/dbt_utils` and `dbt deps` has been run
