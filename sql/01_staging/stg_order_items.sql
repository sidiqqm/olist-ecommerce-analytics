create or replace view `olist-ecommerce-analytics-1.olist_staging.stg_order_items` as

select
    order_id,
    order_item_id,
    product_id,
    seller_id,
    cast(shipping_limit_date as TIMESTAMP) as shipping_limit_date,
    cast(price as NUMERIC) as price,
    cast(freight_value as NUMERIC) as freight_value
from `olist-ecommerce-analytics-1.olist_raw.raw_order_items`