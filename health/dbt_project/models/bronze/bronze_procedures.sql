SELECT
    TRY_TO_TIMESTAMP(start_ts) AS start_time, TRY_TO_TIMESTAMP(stop_ts) AS stop_time,
    TRIM(patient) AS patient_id, TRIM(encounter) AS encounter_id,
    TRIM(code) AS procedure_code, TRIM(description) AS procedure_description,
    TRY_TO_NUMBER(base_cost, 12, 2) AS base_cost
FROM {{ source('staging', 'raw_procedures') }}