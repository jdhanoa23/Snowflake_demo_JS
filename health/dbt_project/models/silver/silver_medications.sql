{{
    config(
        materialized='incremental',
        schema='silver',
        unique_key='medication_id'
    )
}}

-- Medications: incremental upsert. Build a key by concatenation.

SELECT
    patient_id || '-' || encounter_id || '-' || medication_code AS medication_id,
    patient_id,
    encounter_id,
    medication_code,
    medication_description,
    start_time,
    stop_time,
    base_cost,
    payer_coverage,
    dispenses,
    total_cost
FROM {{ ref('bronze_medications') }}
