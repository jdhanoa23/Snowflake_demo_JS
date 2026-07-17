SELECT
    TRIM(id) AS claim_id, TRIM(patient) AS patient_id, TRIM(provider) AS provider_id,
    TRIM(status) AS claim_status, TRY_TO_DATE(outstandingdate) AS outstanding_date,
    TRY_TO_DATE(servicedate) AS service_date
FROM {{ source('staging', 'raw_claims') }}