{{
  config(
    materialized = 'ephemeral'
  )
}}

WITH organizations AS
(
    SELECT
        organization_id,
        hospital_name,
        city,
        state,
        revenue
    FROM
        {{ ref('silver_organizations') }}
)

SELECT * FROM organizations
