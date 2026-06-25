-- Business logic assertion (Critical tier requirement):
-- No order amount should be negative.
SELECT order_id, amount
FROM {{ ref('fact_orders') }}
WHERE amount < 0
