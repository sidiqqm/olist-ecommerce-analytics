CREATE OR REPLACE TABLE
  `olist-ecommerce-analytics-1.olist_intermediate.int_order_details`
PARTITION BY purchase_date
CLUSTER BY order_status, purchase_year_month
AS

WITH payments_aggregated AS (
    SELECT
        order_id,

        SUM(payment_value) AS total_payment_value,

        MAX(
            IF(is_primary_payment, payment_type, NULL)
        ) AS primary_payment_type,

        MAX(
            IF(
                is_installment,
                payment_installments,
                NULL
            )
        ) AS max_installments,

        COUNTIF(payment_type = 'voucher') > 0
            AS used_voucher,

        COUNT(*) > 1 AS is_split_payment,

        COUNT(*) AS payment_record_count,

        COUNT(DISTINCT payment_type)
            AS payment_type_count

    FROM `olist-ecommerce-analytics-1.olist_intermediate.int_order_payments`
    GROUP BY order_id
),

reviews_deduped AS (
    SELECT
        order_id,
        review_score,
        review_sentiment,
        review_score_label,
        has_comment,
        has_responded,
        minutes_to_respond,
        review_answer_timestamp

    FROM `olist-ecommerce-analytics-1.olist_intermediate.int_order_reviews`

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY order_id
        ORDER BY
            review_answer_timestamp DESC NULLS LAST,
            review_score DESC NULLS LAST,
            has_comment DESC NULLS LAST
    ) = 1
),

joined AS (
    SELECT
        oi.order_id,
        oi.order_item_id,
        oi.product_id,
        oi.seller_id,
        o.customer_id,

        o.order_status,
        o.is_revenue_generating,
        o.is_delivered,
        o.is_shipped,
        o.is_approved,
        o.is_ontime_delivery,
        o.is_order_date_anomaly,

        o.order_purchase_timestamp,
        o.order_approved_at,
        o.order_delivered_carrier_date,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date,
        oi.shipping_limit_date,

        o.purchase_date,
        o.purchase_year,
        o.purchase_month,
        o.purchase_day,
        o.purchase_day_of_week,
        o.purchase_year_month,
        o.purchase_year_quarter,

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
        p.product_weight_kg,
        p.has_photos AS product_has_photos,
        p.has_complete_dimensions,

        oi.price,
        oi.freight_value,
        oi.item_gmv,
        oi.freight_to_price_pct,
        oi.is_free_shipping,
        oi.is_zero_or_negative_price,

        pay.total_payment_value,
        pay.primary_payment_type,
        pay.max_installments,
        pay.used_voucher,
        pay.is_split_payment,
        pay.payment_record_count,
        pay.payment_type_count,

        rev.review_score,
        rev.review_sentiment,
        rev.review_score_label,
        rev.has_comment AS review_has_comment,
        rev.has_responded AS review_has_responded,
        rev.minutes_to_respond AS review_hours_to_respond,
        rev.review_answer_timestamp

    FROM `olist-ecommerce-analytics-1.olist_staging.stg_order_items` oi

    INNER JOIN `olist-ecommerce-analytics-1.olist_intermediate.int_orders` o
        ON oi.order_id = o.order_id

    INNER JOIN `olist-ecommerce-analytics-1.olist_staging.stg_customers` c
        ON o.customer_id = c.customer_id

    INNER JOIN `olist-ecommerce-analytics-1.olist_staging.stg_sellers` s
        ON oi.seller_id = s.seller_id

    LEFT JOIN `olist-ecommerce-analytics-1.olist_intermediate.int_products` p
        ON oi.product_id = p.product_id

    LEFT JOIN `olist-ecommerce-analytics-1.olist_staging.stg_product_category_translation` cat
        ON p.product_category_name = cat.product_category_name

    LEFT JOIN payments_aggregated pay
        ON oi.order_id = pay.order_id

    LEFT JOIN reviews_deduped rev
        ON oi.order_id = rev.order_id
)

SELECT
    order_id,
    order_item_id,
    product_id,
    seller_id,
    customer_id,
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
    purchase_date,
    purchase_year,
    purchase_month,
    purchase_day,
    purchase_day_of_week,
    purchase_year_month,
    purchase_year_quarter,
    purchase_to_delivery_days,
    delivery_vs_estimated_days,
    purchase_to_approved_hours,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state,
    customer_region,
    seller_zip_code_prefix,
    seller_city,
    seller_state,
    seller_region,
    is_sao_paulo_seller,
    product_category_name,
    product_category_name_english,
    product_super_category,
    product_weight_g,
    product_weight_kg,
    product_has_photos,
    has_complete_dimensions,
    price,
    freight_value,
    item_gmv,
    freight_to_price_pct,
    is_free_shipping,
    is_zero_or_negative_price,
    total_payment_value,
    primary_payment_type,
    max_installments,
    used_voucher,
    is_split_payment,
    payment_record_count,
    payment_type_count,
    review_score,
    review_sentiment,
    review_score_label,
    review_has_comment,
    review_has_responded,
    review_hours_to_respond,
    review_answer_timestamp
FROM joined;