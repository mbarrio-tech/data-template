-- SPEC: customer running total
-- MODEL: fact_orders
-- TRIGGER: window function — SUM(amount) OVER (PARTITION BY customer_id ORDER BY ordered_date ASC, order_id ASC)
--
-- BEHAVIOUR:
--   For each order (excluding cancelled), compute the cumulative sum of amount
--   for that customer ordered by ordered_date ascending, then order_id ascending
--   as a tie-breaker. The running total includes the current row.
--
-- INPUT:
--   order_id | customer_id | amount | ordered_date | status
--   1001     | 1           | 250.00 | 2024-05-01   | delivered
--   1002     | 1           | 120.00 | 2024-05-15   | delivered
--   1005     | 1           | 250.00 | 2024-06-10   | cancelled  ← excluded by model filter
--   1004     | 3           |  80.00 | 2024-06-01   | delivered
--
-- EXPECTED OUTPUT (after cancelled filter):
--   order_id | customer_id | customer_running_total
--   1001     | 1           | 250.00
--   1002     | 1           | 370.00
--   1004     | 3           |  80.00
--
-- EDGE CASES:
--   - Customer with one order: running total equals amount
--   - Two orders on the same date: tie-broken by order_id ASC (deterministic)
--   - Cancelled orders: excluded before the window is computed
--   - NULL amount: not present in this model (not_null test on amount in schema.yml)
--
-- FAILS WHEN: this query returns rows. Empty result = behaviour is correct.

WITH input_fixture AS (
    SELECT 1001 AS order_id, 1 AS customer_id, 250.00 AS amount,
           DATE '2024-05-01' AS ordered_date, 'delivered' AS status
    UNION ALL
    SELECT 1002, 1, 120.00, DATE '2024-05-15', 'delivered'
    UNION ALL
    SELECT 1005, 1, 250.00, DATE '2024-06-10', 'cancelled'
    UNION ALL
    SELECT 1004, 3,  80.00, DATE '2024-06-01', 'delivered'
),

filtered AS (
    SELECT order_id, customer_id, amount, ordered_date
    FROM input_fixture
    WHERE status != 'cancelled'
),

actual AS (
    SELECT
        order_id,
        customer_id,
        SUM(amount) OVER (
            PARTITION BY customer_id
            ORDER BY ordered_date ASC, order_id ASC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS customer_running_total
    FROM filtered
),

expected AS (
    SELECT 1001 AS order_id, 1 AS customer_id, 250.00 AS customer_running_total
    UNION ALL
    SELECT 1002, 1, 370.00
    UNION ALL
    SELECT 1004, 3,  80.00
),

mismatches AS (
    SELECT
        COALESCE(actual.order_id, expected.order_id) AS order_id,
        actual.customer_running_total AS actual_total,
        expected.customer_running_total AS expected_total
    FROM actual
    FULL OUTER JOIN expected ON actual.order_id = expected.order_id
    WHERE actual.customer_running_total != expected.customer_running_total
       OR actual.order_id IS NULL
       OR expected.order_id IS NULL
)

SELECT * FROM mismatches;
-- Empty result = PASS. Any row = FAIL with diff details.
