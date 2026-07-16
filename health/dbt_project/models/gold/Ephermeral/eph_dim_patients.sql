{{
  config(
    materialized = 'ephemeral'
  )
}}

WITH patients AS
(
    SELECT
        patient_id,
        gender,
        race,
        ethnicity,
        age,
        age_band,
        city,
        state
    FROM
        {{ ref('silver_patients') }}
)

SELECT * FROM patients
