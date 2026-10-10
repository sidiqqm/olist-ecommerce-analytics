-- ============================================================
-- TABLE: olist_intermediate.int_order_details
-- PURPOSE:
--   Wide item-level table untuk kebutuhan downstream
--   item analytics dan fact_order_items.
--
-- GRAIN:
--   1 row per ORDER ITEM
--   unique key = order_id + order_item_id
--
-- IMPORTANT:
--   Order-level measures seperti total_payment_value
--   dan review_score TIDAK disimpan sebagai measures di sini.
--   Keduanya berada di fact_orders karena grain-nya adalah order.
--
-- MATERIALIZED AS TABLE:
--   Karena join beberapa dimension dan digunakan berulang
--   untuk downstream item-level processing.
-- ============================================================

create or replace table
    `olist-ecommerce-analytics-1.olist_intermediate.int_order_details`

partition by purchase_date
cluster by order_status, product_id

as

with joined as (

    select
        oi.order_id,
        oi.order_item_id,

        oi.product_id,
        oi.seller_id,

        o.customer_id,

        o.order_status,

        o.is_revenue_generating,
        o.is_ontime_delivery,
        o.is_order_date_anomaly,

        o.order_purchase_timestamp,
        o.order_approved_at,
        o.order_delivered_carrier_date,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date,

        oi.shipping_limit_date,

        o.purchase_date,

        o.purchase_to_delivery_days,
        o.delivery_vs_estimated_days,
        o.purchase_to_approved_hours,

        c.customer_unique_id,
        c.customer_zip_code_prefix,
        c.customer_city,
        c.customer_state,
        c.customer_region,

        s.seller_zip_code_prefix,
        s.seller_city,
        s.seller_state,
        s.seller_region,
        s.is_sao_paulo_seller,

        p.product_category_name,

        cat.product_category_name_english,
        cat.product_super_category,

        p.product_weight_g,

        p.product_length_cm,
        p.product_height_cm,
        p.product_width_cm,

        p.volumetric_weight_kg,

        p.has_photos as product_has_photos,
        p.has_weight,
        p.has_complete_dimensions,
        p.is_unknown_category,

        oi.price,
        oi.freight_value,
        oi.item_gmv,

        oi.freight_to_price_pct,

        oi.is_free_shipping,
        oi.is_zero_or_negative_price

    from `olist-ecommerce-analytics-1.olist_intermediate.int_order_items` oi

    inner join `olist-ecommerce-analytics-1.olist_intermediate.int_orders` o
        on oi.order_id = o.order_id

    left join `olist-ecommerce-analytics-1.olist_staging.stg_customers` c
        on o.customer_id = c.customer_id

    left join `olist-ecommerce-analytics-1.olist_staging.stg_sellers` s
        on oi.seller_id = s.seller_id

    left join `olist-ecommerce-analytics-1.olist_intermediate.int_products` p
        on oi.product_id = p.product_id

    left join
        `olist-ecommerce-analytics-1.olist_staging.stg_product_category_translation` cat
        on p.product_category_name = cat.product_category_name
)

select
    *
from joined;