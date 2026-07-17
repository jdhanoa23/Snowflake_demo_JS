{{
    config(
        materialized='table',
        schema='gold'
    )
}}

/*
    gold_obt_healthcare_analytics
    One Big Table (OBT) - grain: one row per encounter.
    Built metadata-driven: encounters enriched with patient, provider,
    organization and payor attributes. Feeds the star schema (dims + fact).
*/

{% set configs = [
    {
        "table": ref('silver_encounters'),
        "columns": "e.encounter_id, e.start_time, e.stop_time, e.encounter_class,
                    e.base_encounter_cost, e.total_claim_cost, e.payer_coverage,
                    e.patient_responsibility, e.duration_minutes,
                    e.patient_id, e.provider_id, e.organization_id, e.payor_id",
        "alias": "e"
    },
    {
        "table": ref('silver_patients'),
        "columns": "p.gender AS patient_gender, p.race AS patient_race,
                    p.ethnicity AS patient_ethnicity, p.age, p.age_band,
                    p.city AS patient_city, p.state AS patient_state",
        "alias": "p",
        "join_condition": "e.patient_id = p.patient_id"
    },
    {
        "table": ref('silver_providers'),
        "columns": "pr.doctor_name, pr.specialty",
        "alias": "pr",
        "join_condition": "e.provider_id = pr.provider_id"
    },
    {
        "table": ref('silver_organizations'),
        "columns": "o.hospital_name, o.city AS org_city, o.state AS org_state",
        "alias": "o",
        "join_condition": "e.organization_id = o.organization_id"
    },
    {
        "table": ref('silver_payors'),
        "columns": "pay.payor_name",
        "alias": "pay",
        "join_condition": "e.payor_id = pay.payor_id"
    }
] %}

SELECT
    {% for config in configs %}
        {{ config['columns'] }}{% if not loop.last %},{% endif %}
    {% endfor %}
FROM
    {% for config in configs %}
        {% if loop.first %}
            {{ config['table'] }} AS {{ config['alias'] }}
        {% else %}
            LEFT JOIN {{ config['table'] }} AS {{ config['alias'] }}
                ON {{ config['join_condition'] }}
        {% endif %}
    {% endfor %}
