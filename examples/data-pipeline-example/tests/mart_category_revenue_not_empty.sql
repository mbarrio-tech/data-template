-- Row count anomaly assertion (Critical tier requirement):
-- mart_category_revenue must never be empty. An empty table means the pipeline failed silently.
-- Returns 1 row (test failure) when the table has zero rows.
SELECT 1 AS failure
FROM {{ ref('mart_category_revenue') }}
HAVING COUNT(*) = 0
