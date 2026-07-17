{{
    config(
        materialized='table',
        schema='silver'
    )
}}

-- Conditions: no natural key in source, so build one by concatenation.

SELECT
    patient_id || '-' || encounter_id || '-' || condition_code AS condition_id,
    patient_id,
    encounter_id,
    condition_code,
    condition_description,
    onset_date,
    resolution_date
FROM {{ ref('bronze_conditions') }}
