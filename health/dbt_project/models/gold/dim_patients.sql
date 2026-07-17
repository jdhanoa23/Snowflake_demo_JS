{{
    config(
        materialized='table',
        schema='gold'
    )
}}

-- Patient dimension (from ephemeral slice of silver_patients). All patients included.

SELECT
    patient_id,
    gender,
    race,
    ethnicity,
    age,
    age_band,
    city,
    state
FROM {{ ref('eph_dim_patients') }}
