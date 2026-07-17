SELECT
    TRY_TO_TIMESTAMP(start_ts) AS start_time, TRY_TO_TIMESTAMP(stop_ts) AS stop_time,
    TRIM(patient) AS patient_id, TRIM(encounter) AS encounter_id,
    TRIM(code) AS medication_code, TRIM(description) AS medication_description,
    TRY_TO_NUMBER(base_cost, 12, 2) AS base_cost,
    TRY_TO_NUMBER(payer_coverage, 12, 2) AS payer_coverage,
    TRY_TO_NUMBER(dispenses) AS dispenses,
    TRY_TO_NUMBER(totalcost, 12, 2) AS total_cost
FROM {{ source('staging', 'raw_medications') }}