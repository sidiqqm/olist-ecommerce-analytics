create or replace view `olist-ecommerce-analytics-1.olist_staging.stg_products` as

select
    product_id,
    lower(trim(product_category_name)) as product_category_name,
    product_name_length,
    product_description_length,

    cast(product_photos_qty) as product_photos_qty,

    cast(product_weight_g as NUMERIC) as product_weight_g,
    cast(product_length_cm as NUMERIC) as product_length_cm,
    cast(product_height_cm as NUMERIC) as product_height_cm,
    cast(product_width_cm as NUMERIC) as product_width_cm
from `olist-ecommerce-analyst-1.olist_raw.raw_products`