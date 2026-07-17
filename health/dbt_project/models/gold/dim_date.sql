{{
    config(
        materialized='table',
        schema='gold'
    )
}}

/*
    gold dim_date
    Date dimension for Power BI time intelligence
*/

WITH date_range AS (

    SELECT
        MIN(CAST(start_time AS DATE)) AS min_date,
        MAX(CAST(start_time AS DATE)) AS max_date
    FROM {{ ref('silver_encounters') }}

),

date_spine AS (

    SELECT
        DATEADD('day', SEQ4(), r.min_date) AS date_day,
        r.max_date
    FROM TABLE(GENERATOR(ROWCOUNT => 3660)) g
    CROSS JOIN date_range r

)

SELECT
    CAST(TO_CHAR(date_day, 'YYYYMMDD') AS INT) AS date_key,
    date_day                                   AS full_date,
    YEAR(date_day)                             AS year,
    QUARTER(date_day)                          AS quarter,
    MONTH(date_day)                            AS month_number,
    MONTHNAME(date_day)                        AS month_name,
    DAY(date_day)                              AS day_of_month,
    DAYOFWEEK(date_day)                        AS day_of_week,
    DAYNAME(date_day)                          AS day_name,
    (DAYOFWEEK(date_day) IN (0, 6))            AS is_weekend
FROM date_spine
WHERE date_day <= max_date
