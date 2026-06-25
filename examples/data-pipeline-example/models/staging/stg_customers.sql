WITH source AS (
    SELECT
        customer_id,
        name AS customer_name,
        email,
        country,
        segment,
        created_at::DATE AS created_date
    FROM {{ ref('customers') }}
    WHERE customer_id IS NOT NULL
)

SELECT * FROM source
