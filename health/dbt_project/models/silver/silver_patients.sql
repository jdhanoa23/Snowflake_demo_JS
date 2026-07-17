{{
    config(
        materialized='table',
        schema='silver'
    )
}}

-- Patient dimension: drop PII (ssn), address and zip. Derive age + age_band.

SELECT
    patient_id,
    birth_date,
    death_date,
    first_name,
    last_name,
    gender,
    race,
    ethnicity,
    city,
    state,
    updated_at,

    DATEDIFF('year', birth_date, COALESCE(death_date, CURRENT_DATE())) AS age,

    CASE
        WHEN DATEDIFF('year', birth_date, COALESCE(death_date, CURRENT_DATE())) < 18 THEN '0-17'
        WHEN DATEDIFF('year', birth_date, COALESCE(death_date, CURRENT_DATE())) < 35 THEN '18-34'
        WHEN DATEDIFF('year', birth_date, COALESCE(death_date, CURRENT_DATE())) < 50 THEN '35-49'
        WHEN DATEDIFF('year', birth_date, COALESCE(death_date, CURRENT_DATE())) < 65 THEN '50-64'
        ELSE '65+'
    END AS age_band

FROM {{ ref('bronze_patients') }}
