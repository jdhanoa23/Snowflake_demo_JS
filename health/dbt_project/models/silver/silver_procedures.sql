{{
    config(
        materialized='table',
        schema='silver'
    )
}}

-- Procedures: no natural key in source, so build one by concatenation.

SELECT
    patient_id || '-' || encounter_id || '-' || procedure_code AS procedure_id,
    patient_id,
    encounter_id,
    procedure_code,
    procedure_description,
    start_time,
    stop_time,
    base_cost
FROM {{ ref('bronze_procedures') }}
