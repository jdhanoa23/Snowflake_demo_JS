
SELECT
    TRIM(id)                        AS patient_id,
    TRY_TO_DATE(birthdate)          AS birth_date,
    TRY_TO_DATE(deathdate)          AS death_date,
    TRIM(ssn)                       AS ssn,
    TRIM(first)                     AS first_name,
    TRIM(last)                      AS last_name,
    TRIM(gender)                    AS gender,
    TRIM(race)                      AS race,
    TRIM(ethnicity)                 AS ethnicity,
    TRIM(address)                   AS address,
    TRIM(city)                      AS city,
    TRIM(state)                     AS state,
    TRIM(zip)                       AS zip,
    TRIM(insurance_provider)        AS insurance_provider,
    TRY_TO_TIMESTAMP(updated_at)    AS updated_at
FROM 
{{ source('staging', 'raw_patients') }}