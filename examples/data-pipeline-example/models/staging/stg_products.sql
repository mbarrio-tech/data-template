WITH source AS (
    SELECT
        product_id,
        name AS product_name,
        category,
        unit_price::DECIMAL(10, 2) AS unit_price
    FROM {{ ref('products') }}
    WHERE product_id IS NOT NULL
)

SELECT * FROM source
