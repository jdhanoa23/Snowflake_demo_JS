{{
  config(
    materialized = 'ephemeral'
  )
}}

WITH payors AS
(
    SELECT
        payor_id,
        payor_name,
        city,
        state
    FROM
        {{ ref('silver_payors') }}
)

SELECT * FROM payors
