CREATE OR REPLACE TABLE
  `olist-ecommerce-analytics-1.olist_mart.fact_order_items`
PARTITION BY purchase_date
CLUSTER BY product_id, seller_id
AS

SELECT
    order_id,
    order_item_id,

    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    product_id,
    seller_id,

    purchase_date,
    purchase_year,
    purchase_month,
    purchase_day,
    purchase_day_of_week,
    purchase_year_month,
    purchase_year_quarter,

    order_status,
    is_revenue_generating,
    is_delivered,
    is_shipped,
    is_approved,
    is_ontime_delivery,
    is_order_date_anomaly,

    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    shipping_limit_date,

    product_category_name,
    product_category_name_english,
    product_super_category,
    product_weight_g,
    product_weight_kg,
    product_has_photos,
    has_complete_dimensions,

    customer_city,
    customer_state,
    customer_region,
    seller_zip_code_prefix,
    seller_city,
    seller_state,
    seller_region,
    is_sao_paulo_seller,

    purchase_to_delivery_days,
    delivery_vs_estimated_days,
    purchase_to_approved_hours,

    primary_payment_type,
    max_installments,
    used_voucher,
    is_split_payment,
    payment_record_count,
    payment_type_count,

    price,
    freight_value,
    item_gmv,
    freight_to_price_pct,
    is_free_shipping,
    is_zero_or_negative_price,

    review_score,
    review_sentiment,
    review_score_label,
    review_has_comment,
    review_has_responded,
    review_hours_to_respond,
    review_answer_timestamp

FROM
  `olist-ecommerce-analytics-1.olist_intermediate.int_order_details`;
