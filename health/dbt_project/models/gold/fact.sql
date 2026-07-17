{{
    config(
        materialized='table',
        schema='gold'
    )
}}

/*
    fact (fct_encounters)
    Central fact - grain: one row per encounter.
    Metadata-driven build: silver_encounters joined to dimensions
    (join to dims validates every FK resolves). Holds FKs + measures.
*/

{% set configs = [
    {
        "table": ref('silver_encounters'),
        "columns": "e.encounter_id,
                    e.patient_id,
                    e.provider_id,
                    e.organization_id,
                    e.payor_id,
                    CAST(TO_CHAR(e.start_time, 'YYYYMMDD') AS INT) AS date_key,
                    e.encounter_class,
                    e.base_encounter_cost,
                    e.total_claim_cost,
                    e.payer_coverage,
                    e.patient_responsibility,
                    e.duration_minutes",
        "alias": "e"
    },
    {
        "table": ref('dim_patients'),
        "columns": "",
        "alias": "dp",
        "join_condition": "e.patient_id = dp.patient_id"
    },
    {
        "table": ref('dim_providers'),
        "columns": "",
        "alias": "dpr",
        "join_condition": "e.provider_id = dpr.provider_id"
    },
    {
        "table": ref('dim_organizations'),
        "columns": "",
        "alias": "dorg",
        "join_condition": "e.organization_id = dorg.organization_id"
    },
    {
        "table": ref('dim_payors'),
        "columns": "",
        "alias": "dpay",
        "join_condition": "e.payor_id = dpay.payor_id"
    }
] %}

SELECT
    {{ configs[0]['columns'] }}
FROM
    {% for config in configs %}
        {% if loop.first %}
            {{ config['table'] }} AS {{ config['alias'] }}
        {% else %}
            LEFT JOIN {{ config['table'] }} AS {{ config['alias'] }}
                ON {{ config['join_condition'] }}
        {% endif %}
    {% endfor %}
