-- SPEC: latest record dedup
-- MODEL: dim_customers
-- TRIGGER: deduplication — ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY created_date DESC)
--
-- BEHAVIOUR:
--   For each customer_id, keep only the record with the most recent created_date.
--   When two records share the same created_date, keep the one that appears last
--   in source order (highest implicit row position). The output must contain exactly
--   one row per customer_id.
--
-- INPUT:
--   customer_id | customer_name | created_date
--   1           | Alice v1      | 2024-01-10     ← older record
--   1           | Alice v2      | 2024-06-01     ← newer record — this one wins
--   2           | Bob           | 2024-02-14     ← only record
--
-- EXPECTED OUTPUT:
--   customer_id | customer_name | created_date
--   1           | Alice v2      | 2024-06-01
--   2           | Bob           | 2024-02-14
--
-- EDGE CASES:
--   - Customer with one record: that record is kept unchanged
--   - Customer with two records on the same date: ROW_NUMBER tie-break is deterministic
--     (ORDER BY created_date DESC — equal dates get rn 1 or 2 arbitrarily, so we pick rn = 1)
--   - NULL created_date: treated as oldest (NULLS LAST), never wins over a dated record
--
-- FAILS WHEN: this query returns rows. Empty result = behaviour is correct.

WITH input_fixture AS (
    SELECT 1 AS customer_id, 'Alice v1' AS customer_name, 'alice@example.com' AS email,
           'US' AS country, 'enterprise' AS segment, DATE '2024-01-10' AS created_date
    UNION ALL
    SELECT 1, 'Alice v2', 'alice@example.com', 'US', 'enterprise', DATE '2024-06-01'
    UNION ALL
    SELECT 2, 'Bob', 'bob@example.com', 'UK', 'smb', DATE '2024-02-14'
),

ranked AS (
    SELECT
        customer_id,
        customer_name,
        email,
        country,
        segment,
        created_date,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY created_date DESC
        ) AS rn
    FROM input_fixture
),

actual AS (
    SELECT customer_id, customer_name, created_date
    FROM ranked
    WHERE rn = 1
),

expected AS (
    SELECT 1 AS customer_id, 'Alice v2' AS customer_name, DATE '2024-06-01' AS created_date
    UNION ALL
    SELECT 2, 'Bob', DATE '2024-02-14'
),

mismatches AS (
    SELECT
        COALESCE(actual.customer_id, expected.customer_id) AS customer_id,
        actual.customer_name AS actual_name,
        expected.customer_name AS expected_name,
        actual.created_date AS actual_date,
        expected.created_date AS expected_date
    FROM actual
    FULL OUTER JOIN expected ON actual.customer_id = expected.customer_id
    WHERE actual.customer_name != expected.customer_name
       OR actual.created_date != expected.created_date
       OR actual.customer_id IS NULL
       OR expected.customer_id IS NULL
)

SELECT * FROM mismatches;
-- Empty result = PASS. Any row = FAIL with diff details.
