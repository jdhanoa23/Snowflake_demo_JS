{{
    config(
        materialized='table',
        schema='silver'
    )
}}

-- Organization (hospital) dimension: drop address, phone, zip.

SELECT
    organization_id,
    hospital_name,
    city,
    state,
    revenue
FROM {{ ref('bronze_organizations') }}
