WITH source AS (
    SELECT
        order_id,
        customer_id,
        product_id,
        status,
        amount::DECIMAL(10, 2) AS amount,
        ordered_at::DATE AS ordered_date,
        shipped_at::DATE AS shipped_date,
        delivered_at::DATE AS delivered_date
    FROM {{ ref('orders') }}
    WHERE order_id IS NOT NULL
)

SELECT * FROM source
