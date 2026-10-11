create or replace view `olist-ecommerce-analytics-1.olist_intermediate.int_products_metrics` as

with product_metrics as (
    select
        product_id,
        count(*) as total_units_sold,
        count(distinct order_id) as total_orders,
        round(sum(price),2) as total_revenue,
        round(avg(price),2) as avg_selling_price,
        round(avg(review_score),1) as avg_review_score,
        round(avg(purchase_to_delivery_days),1) as avg_delivery_days
    from `olist-ecommerce-analytics-1.olist_staging.stg_order_items` oi
    where is_revenue_generating = true
    group by product_id
),

select
    p.product_id,
    
    p.product_category_name,
    cat.product_category_name_english,
    cat.product_super_category,
    p.is_unknown_category,

    p.product_name_length,
    p.product_description_length,
    p.product_photos_qty,
    p.has_photos,
    p.has_complete_dimensions,

    p.product_weight_g,
    p.product_weight_kg,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm,
    p.volumetric_weight_kg,

    coalesce(pm.total_units_sold, 0) as total_units_sold,
    coalesce(pm.total_orders, 0) as total_orders,
    coalesce(pm.total_revenue, 0) as total_revenue,
    pm.avg_selling_price as avg_selling_price,
    pm.avg_review_score as avg_review_score,
    pm.avg_delivery_days as avg_delivery_days,

    round(
        (
            case when p.has_photos is not null then 30 else 0 end
            + case when p.product_photos_qty >= 3 then 20 else 0 end
            + case when p.product_description_length > 100 then 25 else 0 end
            + case when p.has_complete_dimensions then 25 else 0 end
        ) / 100.0 * 100,
        0
    ) as listing_quality_score

from `olist-ecommerce-analytics-1.olist_intermediate.int_products` p
left join `olist-ecommerce-analytics-1.olist_staging.stg_product_category_translation` cat
    on p.product_category_name = cat.product_category_name
left join product_metrics pm
    on p.product_id = pm.product_id
;