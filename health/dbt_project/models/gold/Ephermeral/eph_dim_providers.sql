{{
  config(
    materialized = 'ephemeral'
  )
}}

WITH providers AS
(
    SELECT
        provider_id,
        doctor_name,
        specialty,
        city,
        state
    FROM
        {{ ref('silver_providers') }}
)

SELECT * FROM providers
