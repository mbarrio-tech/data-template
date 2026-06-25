-- Window function trigger: running total per customer.
-- SPEC: specs/fact_orders/customer-running-total.spec.sql
WITH filtered_orders AS (
    SELECT
        order_id,
        customer_id,
        product_id,
        status,
        amount,
        ordered_date,
        shipped_date,
        delivered_date
    FROM {{ ref('stg_orders') }}
    WHERE status != 'cancelled'
),

enriched AS (
    SELECT
        fo.order_id,
        fo.customer_id,
        fo.product_id,
        p.product_name,
        p.category AS product_category,
        fo.status,
        fo.amount,
        fo.ordered_date,
        fo.shipped_date,
        fo.delivered_date,
        SUM(fo.amount) OVER (
            PARTITION BY fo.customer_id
            ORDER BY fo.ordered_date ASC, fo.order_id ASC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS customer_running_total
    FROM filtered_orders AS fo
    JOIN {{ ref('stg_products') }} AS p ON fo.product_id = p.product_id
)

SELECT * FROM enriched
