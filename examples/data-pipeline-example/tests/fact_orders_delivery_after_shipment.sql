-- Business logic assertion (Critical tier requirement):
-- A delivered order must have a delivered_date >= shipped_date.
-- Rows that violate this rule are returned (non-empty = test failure).
SELECT order_id, shipped_date, delivered_date
FROM {{ ref('fact_orders') }}
WHERE delivered_date IS NOT NULL
  AND shipped_date IS NOT NULL
  AND delivered_date < shipped_date
