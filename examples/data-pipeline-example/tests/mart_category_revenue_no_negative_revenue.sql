-- Business logic assertion (Critical tier requirement):
-- total_revenue must never be negative. A negative revenue total indicates
-- corrupt source data or an incorrect aggregation.
-- Returns rows (test failure) when any category has negative total_revenue.
SELECT
    product_category,
    total_revenue
FROM {{ ref('mart_category_revenue') }}
WHERE total_revenue < 0
