{{
    config(
        materialized='table',
        schema='silver'
    )
}}

-- Payor (insurance) dimension: drop address, phone, zip.

SELECT
    payor_id,
    payor_name,
    city,
    state
FROM {{ ref('bronze_payors') }}
