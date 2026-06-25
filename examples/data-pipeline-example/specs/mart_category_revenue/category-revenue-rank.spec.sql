-- SPEC: category revenue rank
-- MODEL: mart_category_revenue
-- TRIGGER: window function — RANK() OVER (ORDER BY total_revenue DESC)
--
-- BEHAVIOUR:
--   After aggregating total revenue and order count per product_category,
--   rank each category by total_revenue descending. The highest-revenue category
--   receives rank 1. Categories with equal revenue receive the same rank, and the
--   next rank is skipped (standard RANK() semantics — not DENSE_RANK()).
--
-- INPUT (orders, pre-aggregation):
--   order_id | product_category | amount
--   1        | software         | 500.00
--   2        | software         | 300.00
--   3        | hardware         | 800.00
--   4        | service          | 300.00
--   5        | service          | 500.00
--
-- Aggregated totals:
--   software  → total_revenue = 800.00, order_count = 2
--   hardware  → total_revenue = 800.00, order_count = 1
--   service   → total_revenue = 800.00, order_count = 2
--
-- EXPECTED OUTPUT:
--   product_category | total_revenue | order_count | revenue_rank
--   software         | 800.00        | 2           | 1
--   hardware         | 800.00        | 1           | 1
--   service          | 800.00        | 2           | 1
--
-- EDGE CASES:
--   - All categories have identical revenue: all receive rank 1 (RANK() tie behaviour)
--   - Single category: receives rank 1 regardless of revenue amount
--   - Category with highest revenue always receives rank 1
--
-- FAILS WHEN: this query returns rows. Empty result = behaviour is correct.

WITH input_fixture AS (
    SELECT
        1 AS order_id,
        'software' AS product_category,
        500.00 AS amount
    UNION ALL
    SELECT
        2 AS order_id,
        'software' AS product_category,
        300.00 AS amount
    UNION ALL
    SELECT
        3 AS order_id,
        'hardware' AS product_category,
        800.00 AS amount
    UNION ALL
    SELECT
        4 AS order_id,
        'service' AS product_category,
        300.00 AS amount
    UNION ALL
    SELECT
        5 AS order_id,
        'service' AS product_category,
        500.00 AS amount
),

aggregated AS (
    SELECT
        product_category,
        SUM(amount) AS total_revenue,
        COUNT(order_id) AS order_count
    FROM input_fixture
    GROUP BY product_category
),

actual AS (
    SELECT
        product_category,
        total_revenue,
        order_count,
        RANK() OVER (
            ORDER BY total_revenue DESC
        ) AS revenue_rank
    FROM aggregated
),

expected AS (
    SELECT
        'software' AS product_category,
        800.00 AS total_revenue,
        2 AS order_count,
        1 AS revenue_rank
    UNION ALL
    SELECT
        'hardware' AS product_category,
        800.00 AS total_revenue,
        1 AS order_count,
        1 AS revenue_rank
    UNION ALL
    SELECT
        'service' AS product_category,
        800.00 AS total_revenue,
        2 AS order_count,
        1 AS revenue_rank
),

mismatches AS (
    SELECT
        actual.total_revenue AS actual_total_revenue,
        actual.order_count AS actual_order_count,
        actual.revenue_rank AS actual_revenue_rank,
        expected.total_revenue AS expected_total_revenue,
        expected.order_count AS expected_order_count,
        expected.revenue_rank AS expected_revenue_rank,
        COALESCE(actual.product_category, expected.product_category) AS product_category
    FROM actual
    FULL OUTER JOIN expected
        ON actual.product_category = expected.product_category
    WHERE
        actual.revenue_rank != expected.revenue_rank
        OR actual.total_revenue != expected.total_revenue
        OR actual.order_count != expected.order_count
        OR actual.product_category IS NULL
        OR expected.product_category IS NULL
)

SELECT * FROM mismatches;
-- Empty result = PASS. Any row = FAIL with diff details.
