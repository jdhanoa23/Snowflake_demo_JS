{{
    config(
        materialized='table',
        schema='silver'
    )
}}

-- Provider dimension: drop address, gender, zip.

SELECT
    provider_id,
    organization_id,
    doctor_name,
    specialty,
    city,
    state
FROM {{ ref('bronze_providers') }}
