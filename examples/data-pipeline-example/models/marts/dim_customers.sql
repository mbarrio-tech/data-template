-- Deduplication trigger: ROW_NUMBER() picks latest record per customer.
-- SPEC: specs/dim_customers/latest-record-dedup.spec.sql
WITH source AS (
    SELECT
        customer_id,
        customer_name,
        email,
        country,
        segment,
        created_date,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY created_date DESC
        ) AS rn
    FROM {{ ref('stg_customers') }}
),

deduplicated AS (
    SELECT
        customer_id,
        customer_name,
        email,
        country,
        segment,
        created_date
    FROM source
    WHERE rn = 1
)

SELECT * FROM deduplicated
