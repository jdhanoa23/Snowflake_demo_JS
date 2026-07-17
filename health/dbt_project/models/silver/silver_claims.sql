{{
    config(
        materialized='table',
        schema='silver'
    )
}}

-- Claims: PK claim_id. Flag outstanding claims.

SELECT
    claim_id,
    patient_id,
    provider_id,
    claim_status,
    service_date,
    outstanding_date,
    (outstanding_date IS NOT NULL) AS is_outstanding
FROM {{ ref('bronze_claims') }}
