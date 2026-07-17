{{
    config(
        materialized='table',
        schema='gold'
    )
}}

-- Payor dimension (from ephemeral slice of silver_payors).

SELECT
    payor_id,
    payor_name,
    city,
    state
FROM {{ ref('eph_dim_payors') }}
