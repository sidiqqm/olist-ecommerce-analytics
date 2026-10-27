-- PRODUCT TRANSACTION METRICS
-- GRAIN: 1 row per product_id

CREATE OR REPLACE VIEW
  `olist-ecommerce-analytics-1.olist_intermediate.int_products_metrics`
AS

WITH 
product_metrics AS (


    SELECT
        product_id,

        COUNT(*) AS total_units_sold,

        COUNT(DISTINCT order_id) AS total_orders,

        COUNT(DISTINCT customer_unique_id)
            AS total_unique_customers,

        ROUND(SUM(price), 2)
            AS total_revenue,

        ROUND(SUM(item_gmv), 2)
            AS total_item_gmv,

        ROUND(AVG(price), 2)
            AS avg_selling_price,

        ROUND(SUM(freight_value), 2)
            AS total_freight_value,

        ROUND(AVG(freight_to_price_pct), 2)
            AS avg_freight_to_price_pct,

        COUNTIF(is_free_shipping = TRUE)
            AS free_shipping_units,

        ROUND(
            100 * SAFE_DIVIDE(
                COUNTIF(is_free_shipping = TRUE),
                COUNT(*)
            ),
            2
        ) AS free_shipping_rate_pct,

        ROUND(
            AVG(
                IF(
                    is_delivered = TRUE,
                    purchase_to_delivery_days,
                    NULL
                )
            ),
            1
        ) AS avg_delivery_days,

        ROUND(
            AVG(
                IF(
                    is_delivered = TRUE,
                    delivery_vs_estimated_days,
                    NULL
                )
            ),
            1
        ) AS avg_delivery_vs_estimate_days,

        COUNTIF(is_ontime_delivery = TRUE)
            AS on_time_delivery_items,

        COUNTIF(is_ontime_delivery = FALSE)
            AS late_delivery_items,

        ROUND(
            100 * SAFE_DIVIDE(
                COUNTIF(is_ontime_delivery = TRUE),
                COUNTIF(is_delivered = TRUE)
            ),
            2
        ) AS on_time_delivery_rate_pct,

        COUNTIF(is_order_date_anomaly = TRUE)
            AS delivery_anomaly_items,

        ROUND(AVG(review_score), 2)
            AS avg_review_score,

        COUNTIF(review_score IS NOT NULL)
            AS reviewed_order_items,

        COUNTIF(review_sentiment = 'positive')
            AS positive_review_items,

        COUNTIF(review_sentiment = 'neutral')
            AS neutral_review_items,

        COUNTIF(review_sentiment = 'negative')
            AS negative_review_items,

        COUNTIF(review_has_comment = TRUE)
            AS reviews_with_comment,

        COUNTIF(review_has_responded = TRUE)
            AS reviews_responded,

        ROUND(
            100 * SAFE_DIVIDE(
                COUNTIF(review_has_responded = TRUE),
                COUNTIF(review_score IS NOT NULL)
            ),
            2
        ) AS review_response_rate_pct,

        COUNTIF(used_voucher = TRUE)
            AS voucher_order_items,

        ROUND(
            100 * SAFE_DIVIDE(
                COUNTIF(used_voucher = TRUE),
                COUNT(*)
            ),
            2
        ) AS voucher_usage_rate_pct,

        COUNTIF(is_split_payment = TRUE)
            AS split_payment_order_items,

        COUNTIF(primary_payment_type = 'credit_card')
            AS credit_card_order_items,

        COUNTIF(primary_payment_type = 'boleto')
            AS boleto_order_items,

        COUNTIF(primary_payment_type = 'voucher')
            AS voucher_payment_order_items,

        COUNTIF(primary_payment_type = 'debit_card')
            AS debit_card_order_items

    FROM
        `olist-ecommerce-analytics-1.olist_intermediate.int_order_details`

    WHERE
        is_revenue_generating = TRUE

    GROUP BY
        product_id
),

product_enriched AS (
    SELECT
        p.*,

        -- Sales metrics
        COALESCE(pm.total_units_sold, 0)
            AS total_units_sold,

        COALESCE(pm.total_orders, 0)
            AS total_orders,

        COALESCE(pm.total_unique_customers, 0)
            AS total_unique_customers,

        COALESCE(pm.total_revenue, 0)
            AS total_revenue,

        COALESCE(pm.total_item_gmv, 0)
            AS total_item_gmv,

        pm.avg_selling_price,

        COALESCE(pm.total_freight_value, 0)
            AS total_freight_value,

        pm.avg_freight_to_price_pct,

        COALESCE(pm.free_shipping_units, 0)
            AS free_shipping_units,

        pm.free_shipping_rate_pct,

        -- Delivery metrics
        pm.avg_delivery_days,
        pm.avg_delivery_vs_estimate_days,

        COALESCE(pm.on_time_delivery_items, 0)
            AS on_time_delivery_items,

        COALESCE(pm.late_delivery_items, 0)
            AS late_delivery_items,

        pm.on_time_delivery_rate_pct,

        COALESCE(pm.delivery_anomaly_items, 0)
            AS delivery_anomaly_items,

        -- Review metrics
        pm.avg_review_score,

        COALESCE(pm.reviewed_order_items, 0)
            AS reviewed_order_items,

        COALESCE(pm.positive_review_items, 0)
            AS positive_review_items,

        COALESCE(pm.neutral_review_items, 0)
            AS neutral_review_items,

        COALESCE(pm.negative_review_items, 0)
            AS negative_review_items,

        COALESCE(pm.reviews_with_comment, 0)
            AS reviews_with_comment,

        COALESCE(pm.reviews_responded, 0)
            AS reviews_responded,

        pm.review_response_rate_pct,

        -- Payment metrics
        COALESCE(pm.voucher_order_items, 0)
            AS voucher_order_items,

        pm.voucher_usage_rate_pct,

        COALESCE(pm.split_payment_order_items, 0)
            AS split_payment_order_items,

        COALESCE(pm.credit_card_order_items, 0)
            AS credit_card_order_items,

        COALESCE(pm.boleto_order_items, 0)
            AS boleto_order_items,

        COALESCE(pm.voucher_payment_order_items, 0)
            AS voucher_payment_order_items,

        COALESCE(pm.debit_card_order_items, 0)
            AS debit_card_order_items

    FROM `olist-ecommerce-analytics-1.olist_intermediate.int_products` p

    LEFT JOIN product_metrics pm
        ON p.product_id = pm.product_id
)

-- FINAL PRODUCT INTERMEDIATE

SELECT
    pe.*,

    cat.product_category_name_english,
    cat.product_super_category,

    ROUND(
        CASE
            WHEN pe.has_photos = TRUE THEN 30
            ELSE 0
        END
        +
        CASE
            WHEN pe.product_photos_qty >= 3 THEN 20
            ELSE 0
        END
        +
        CASE
            WHEN pe.product_description_length > 100 THEN 25
            ELSE 0
        END
        +
        CASE
            WHEN pe.has_complete_dimensions = TRUE THEN 25
            ELSE 0
        END,
        0
    ) AS listing_quality_score

FROM product_enriched pe

LEFT JOIN
    `olist-ecommerce-analytics-1.olist_staging.stg_product_category_translation` cat
    ON pe.product_category_name = cat.product_category_name;
