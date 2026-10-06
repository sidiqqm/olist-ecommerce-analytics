create or replace view `olist-ecommerce-analytics-1.olist_staging.stg_product_category_translation` as

with base as (

    select
        lower(trim(product_category_name))
            as product_category_name,

        trim(product_category_name_english)
            as product_category_name_english

    from `olist-ecommerce-analytics-1.olist_raw.raw_product_category_translation`

),

with_unknown as (

    select
        product_category_name,
        product_category_name_english

    from base

    union all

    select
        'unknown' as product_category_name,
        'Unknown Category' as product_category_name_english

    where not exists (
        select 1
        from base
        where product_category_name = 'unknown'
    )

)

select
    product_category_name,
    product_category_name_english

from with_unknown;