create or replace view `olist-ecommerce-analytics-1.olist_staging.stg_products` as

select
    product_id,
    coalesce(nullif(lower(trim(product_category_name)), ""), "unknown") as product_category_name,
    
    cast(product_name_lenght as INT64) as product_name_length,
    cast(product_description_lenght as INT64) as product_description_length,

    cast(product_photos_qty as INT64) as product_photos_qty,

    cast(product_weight_g as NUMERIC) as product_weight_g,
    cast(product_length_cm as NUMERIC) as product_length_cm,
    cast(product_height_cm as NUMERIC) as product_height_cm,
    cast(product_width_cm as NUMERIC) as product_width_cm,

    case
        when product_length_cm is not null
            and product_height_cm is not null
            and product_width_cm is not null
        then true
        else false
    end as has_complete_dimensions,

    case
        when product_weight_g is not null
        then true
        else false
    end as has_weight,

    case
        when product_photos_qty > 0 then true
        when product_photos_qty = 0 then false
        else null
    end as has_photos,
    
    -- Potensi ada perbedaan review score jika memiliki foto atau tidak
    product_category_name = 'unknown' as is_unknown_category,

from `olist-ecommerce-analytics-1.olist_raw.raw_products`