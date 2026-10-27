CREATE OR REPLACE TABLE `olist-ecommerce-analytics-1.olist_mart.dim_date` AS

WITH date_spine AS (
    SELECT
        DATE_ADD(
            DATE '2016-01-01',
            INTERVAL offset_days DAY
        ) AS date_actual
    FROM UNNEST(
        GENERATE_ARRAY(
            0,
            DATE_DIFF(
                DATE '2018-12-31',
                DATE '2016-01-01',
                DAY
            )
        )
    ) AS offset_days
)

SELECT
    CAST(FORMAT_DATE('%Y%m%d', date_actual) AS INT64) AS date_key,
    date_actual,

    EXTRACT(YEAR FROM date_actual) AS year,

    EXTRACT(QUARTER FROM date_actual) AS quarter,

    CONCAT(
        'Q',
        CAST(EXTRACT(QUARTER FROM date_actual) AS STRING)
    ) AS quarter_label,

    CONCAT(
        CAST(EXTRACT(YEAR FROM date_actual) AS STRING),
        '-Q',
        CAST(EXTRACT(QUARTER FROM date_actual) AS STRING)
    ) AS quarter_year,

    EXTRACT(MONTH FROM date_actual) AS month_actual,
    FORMAT_DATE('%B', date_actual) AS month_name,
    FORMAT_DATE('%b', date_actual) AS month_name_short,
    FORMAT_DATE('%Y-%m', date_actual) AS month_year,

    EXTRACT(WEEK FROM date_actual) AS week_of_year,
    EXTRACT(ISOWEEK FROM date_actual) AS iso_week,
    FORMAT_DATE('%G-W%V', date_actual) AS iso_year_week,

    EXTRACT(DAY FROM date_actual) AS day_of_month,
    EXTRACT(DAYOFWEEK FROM date_actual) AS day_of_week,

    EXTRACT(DAYOFWEEK FROM date_actual) IN (1, 7) AS is_weekend,

    EXTRACT(DAYOFWEEK FROM date_actual) NOT IN (1, 7) AS is_weekday,

    date_actual BETWEEN DATE '2016-09-01' AND DATE '2018-09-03'
        AS is_in_dataset_range,

    -- Brazil federal holidays
    CASE
        WHEN FORMAT_DATE('%m-%d', date_actual) IN (
            '01-01', -- Ano Novo
            '04-21', -- Tiradentes
            '05-01', -- Dia do Trabalho
            '09-07', -- Independência do Brasil
            '10-12', -- Nossa Senhora Aparecida
            '11-02', -- Finados
            '11-15', -- Proclamação da República
            '12-25'  -- Natal
        )
        OR date_actual IN (
            DATE '2016-02-08', DATE '2016-02-09', -- Carnaval 2016
            DATE '2017-02-27', DATE '2017-02-28', -- Carnaval 2017
            DATE '2018-02-12', DATE '2018-02-13'  -- Carnaval 2018
        )
        THEN TRUE
        ELSE FALSE
    END AS is_brazil_holiday,

    -- Retail seasonality
    CASE
        -- Black Friday
        WHEN date_actual IN (
            DATE '2016-11-25',
            DATE '2017-11-24',
            DATE '2018-11-23'
        )
        THEN 'Black Friday'

        -- Christmas season
        WHEN FORMAT_DATE('%m-%d', date_actual)
            BETWEEN '12-15' AND '12-31'
        THEN 'Christmas Season'

        -- Valentine's Day Brazil: June 12
        WHEN FORMAT_DATE('%m-%d', date_actual)
            BETWEEN '06-05' AND '06-12'
        THEN 'Valentines Week'

        -- Mother's Day Brazil
        WHEN date_actual IN (
            DATE '2016-05-08',
            DATE '2017-05-14',
            DATE '2018-05-13'
        )
        THEN 'Mothers Day'

        ELSE 'Regular'
    END AS retail_season,

    EXTRACT(DAYOFYEAR FROM date_actual) AS day_of_year,

    EXTRACT(
        DAY FROM DATE_SUB(
            DATE_ADD(
                DATE_TRUNC(date_actual, MONTH),
                INTERVAL 1 MONTH
            ),
            INTERVAL 1 DAY
        )
    ) AS days_in_month,

    DATE_TRUNC(date_actual, MONTH) AS first_day_of_month,
    DATE_TRUNC(date_actual, QUARTER) AS first_day_of_quarter,
    DATE_TRUNC(date_actual, YEAR) AS first_day_of_year,
    DATE_TRUNC(date_actual, WEEK(MONDAY)) AS first_day_of_week

FROM date_spine;
