create or replace view `olist-ecommerce-analytics-1.olist_mart.dim_sellers` as

select
    s.seller_id,
    s.seller_zip_code_prefix,
    s.seller_city,
    s.seller_state,
    s.seller_region,

    g.state_name as seller_state_name,
    g.latitude as seller_latitude,
    g.longitude as seller_longitude,
    s.seller_state = 'SP' as is_sao_paulo_seller

from `olist-ecommerce-analytics-1.olist_staging.stg_sellers` as s
left join `olist-ecommerce-analytics-1.olist_mart.dim_geography` as g
    on s.seller_zip_code_prefix = g.zip_code_prefix;