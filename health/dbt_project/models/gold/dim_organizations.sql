{{
    config(
        materialized='table',
        schema='gold'
    )
}}

-- Organization dimension (from ephemeral slice of silver_organizations).

SELECT
    organization_id,
    hospital_name,
    city,
    state,
    revenue
FROM {{ ref('eph_dim_organizations') }}
