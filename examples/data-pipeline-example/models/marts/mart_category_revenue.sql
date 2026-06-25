-- Window function trigger: RANK() per category revenue.
-- SPEC: specs/mart_category_revenue/category-revenue-rank.spec.sql
WITH filtered_orders AS (
    SELECT
        order_id,
        product_category,
        amount
    FROM {{ ref('fact_orders') }}
    WHERE amount >= 0
),

aggregated AS (
    SELECT
        product_category,
        SUM(amount) AS total_revenue,
        COUNT(order_id) AS order_count
    FROM filtered_orders
    GROUP BY product_category
)

SELECT
    product_category,
    total_revenue,
    order_count,
    RANK() OVER (
        ORDER BY total_revenue DESC
    ) AS revenue_rank
FROM aggregated
