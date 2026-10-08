create or replace table `olist-ecommerce-analytics-1.olist_mart.dim_date` as

with date_spine as (
    select
        date_add(
            date '2016-01-01',
            interval offset_days day
        ) as date_actual
    from unnest(
        generate_array(
            0,
            date_diff(
                date '2018-12-31',
                date '2016-01-01',
                day
            )
        )
    )
)

select 
    cast(format_date('YYYY-MM-DD', date actual) as int64) as date_key,
    date_actual,
    extract(year from date_actual) as year,

    extract(quarter from date_actual) as quarter,
    concat(
        'Q', cast(extract(quarter from date_actual) as string)
    ) as quarter_label,
    
    concat(
        cast(year from date_actual) as string,
        '-Q',
        cast(quarter from date_actual) as string
    ) as quarter_year,

    extract(month from date_actual) as month_actual,
    format_date('%B',date_actual) as month_name,
    format_date('%b', date_actual) as month_name_short,
    format_date('%Y-%m', date_actual) as month_year,

    extract(week from date_actual) as week_of_year,
    extract(isoweek from date_actual) as iso_week,
    format_date('%G-W%V', date_actual) as iso_year_week,

    extract(day from date_actual) as day_of_month,
    extract(dayofweek from date_actual) as day_of_week,

    case
        when extract(dayofweek from date_actual) in (1, 7)
            then true
        else false
    end as is_weekend,

    case
        when extract(dayofweek from date_actual) not in (1, 7)
            then true
        else false
    end as is_weekday,

    case
        when date_actual BETWEEN DATE '2016-09-01' AND DATE '2018-09-03'
        then true
        else false
    end as is_in_dataset_range,

    -- Brazil public holidays (federal holidays 2016-2018)
    case
        when FORMAT_DATE('%m-%d', date_actual) IN (
            '01-01',  -- Ano Novo (New Year)
            '04-21',  -- Tiradentes
            '05-01',  -- Dia do Trabalho (Labor Day)
            '09-07',  -- Independência do Brasil
            '10-12',  -- Nossa Senhora Aparecida
            '11-02',  -- Finados
            '11-15',  -- Proclamação da República
            '12-25'   -- Natal (Christmas)
        )
        or (date_actual IN (
            date '2016-02-08', date '2016-02-09',  -- Carnaval 2016
            date '2017-02-27', date '2017-02-28',  -- Carnaval 2017
            date '2018-02-12', date '2018-02-13'   -- Carnaval 2018
        ))
        then true
        else false
    end as is_brazil_holiday,

    -- Penting untuk e-commerce seasonality analysis
    case
        -- Black Friday: 4th Friday of November
        when date_actual IN (
            date '2016-11-25',  -- Black Friday 2016
            date '2017-11-24',  -- Black Friday 2017
            date '2018-11-23'   -- Black Friday 2018
        ) then 'Black Friday'

        -- Christmas season
        when FORMAT_DATE('%m-%d', date_actual) BETWEEN '12-15' AND '12-31'
        then 'Christmas Season'

        -- Valentine's Day Brazil (Dia dos Namorados = June 12)
        when FORMAT_DATE('%m', date_actual) = '06'
             AND FORMAT_DATE('%d', date_actual) BETWEEN '05' AND '12'
        then 'Valentines Week'

        -- Mothers Day Brazil (2nd Sunday of May)
        when date_actual IN (
            date '2016-05-08',
            date '2017-05-14',
            date '2018-05-13'
        ) then 'Mothers Day'

        else 'Regular'
    end as retail_season,

    extract(dayofyear from date_actual) as day_of_year,
    extract(day from date_sub(
        date_trunc(
            date_add(date_actual, interval 1 month), month),
            interval 1 day
    )) as days_in_month,

    -- First day of period (untuk aggregasi)
    date_trunc(date_actual, month) as first_day_of_month,
    date_trunc(date_actual, quarter) as first_day_of_quarter,
    date_trunc(date_actual, year) as first_day_of_year,
    date_trunc(date_actual, week(monday)) as first_day_of_week

from date_spine;
    
    
    