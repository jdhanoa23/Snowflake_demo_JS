
SELECT
    TRIM(id)                            AS encounter_id,
    TRY_TO_TIMESTAMP(start_ts)          AS start_time,
    TRY_TO_TIMESTAMP(stop_ts)           AS stop_time,
    TRIM(patient)                       AS patient_id,
    TRIM(organization)                  AS organization_id,
    TRIM(provider)                      AS provider_id,
    TRIM(payor)                         AS payor_id,
    TRIM(encounterclass)                AS encounter_class,
    TRIM(code)                          AS encounter_code,
    TRIM(description)                   AS encounter_description,
    TRY_TO_NUMBER(base_encounter_cost, 12, 2) AS base_encounter_cost,
    TRY_TO_NUMBER(total_claim_cost, 12, 2)    AS total_claim_cost,
    TRY_TO_NUMBER(payer_coverage, 12, 2)      AS payer_coverage,
    TRIM(reasoncode)                    AS reason_code,
    TRIM(reasondescription)             AS reason_description
FROM {{ source('staging', 'raw_encounters') }}