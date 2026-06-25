-- Row count anomaly assertion (Critical tier requirement):
-- fact_orders must never be empty. An empty table means the pipeline failed silently.
-- Returns 1 row (test failure) when the table has zero rows.
SELECT 1 AS failure
FROM {{ ref('fact_orders') }}
HAVING COUNT(*) = 0
