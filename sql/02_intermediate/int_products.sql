create or replace view `olist-ecommerce-analytics-1.olist_intermediate.int_products` as

with metrics as (
    select
        product_id,
        product_category_name,
        product_name_length,
        product_description_length,

        product_photos_qty,
        product_weight_g,
        product_length_cm,
        product_height_cm,
        product_width_cm,

        has_complete_dimensions,
        has_weight,
        has_photos,
        is_unknown_category,

        -- Estimated volumetric weight using divisor 6000, Divisor 6000 is an analytical assumption
        -- Volumetric weight (kg) = L × W × H / 6000
        case
            when product_width_cm is not null
                and product_length_cm is not null
                and product_height_cm is not null
                then round(
                    (product_width_cm * product_length_cm * product_height_cm) / 6000, 3
                )
            else null
        end as volumetric_weight_kg,

        -- aktual weight dalam kg
        case
            when product_weight_g is not null
                then round(product_weight_g / 1000, 3)
            else null
        end as weight_kg,
        
    from `olist-ecommerce-analytics-1.olist_staging.stg_products`
)

select
    product_id,
    product_category_name,
    product_name_length,
    product_description_length,
    
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm,
    
    volumetric_weight_kg,
    weight_kg,

    has_complete_dimensions,
    has_weight,
    has_photo,
    is_unknown_category,
    
from metrics;