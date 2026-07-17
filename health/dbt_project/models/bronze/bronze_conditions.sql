SELECT
    TRY_TO_DATE(start_ts) AS onset_date, TRY_TO_DATE(stop_ts) AS resolution_date,
    TRIM(patient) AS patient_id, TRIM(encounter) AS encounter_id,
    TRIM(code) AS condition_code, TRIM(description) AS condition_description
FROM {{ source('staging', 'raw_conditions') }}