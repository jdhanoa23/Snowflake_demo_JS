{{
    config(
        materialized='incremental',
        schema='silver',
        unique_key='encounter_id'
    )
}}

-- Encounters: incremental upsert on encounter_id.
-- Drop free-text / constant columns. Derive patient_responsibility + duration.

SELECT
    encounter_id,
    start_time,
    stop_time,
    patient_id,
    organization_id,
    provider_id,
    payor_id,
    encounter_class,
    base_encounter_cost,
    total_claim_cost,
    payer_coverage,

    (total_claim_cost - payer_coverage) AS patient_responsibility,
    DATEDIFF('minute', start_time, stop_time) AS duration_minutes

FROM {{ ref('bronze_encounters') }}
