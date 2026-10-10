create or replace view `olist-ecommerce-analytics-1.olist_mart.dim_sellers` as

select
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state,
    seller_region,
    is_sao_paulo_seller,
    is_sao_paulo_city
from `olist-ecommerce-analytics-1.olist_staging.stg_sellers`