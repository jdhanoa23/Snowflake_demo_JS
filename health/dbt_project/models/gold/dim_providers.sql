{{
    config(
        materialized='table',
        schema='gold'
    )
}}

-- Provider dimension (from ephemeral slice of silver_providers).

SELECT
    provider_id,
    doctor_name,
    specialty,
    city,
    state
FROM {{ ref('eph_dim_providers') }}
