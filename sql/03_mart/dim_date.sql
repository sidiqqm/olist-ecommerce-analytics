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

    extract(month from date_actual) as month,
    
    
    
    