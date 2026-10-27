-- ============================================================
-- TABLE: olist_mart.fact_orders
-- PURPOSE: Fact table utama pada grain order level.
--
-- GRAIN: 1 row per order_id
-- PARTITION BY: purchase_date
-- CLUSTER BY: order_status, purchase_year_month
--
-- NOTE:
-- - Order attributes diambil satu kali per order.
-- - Item measures diagregasi dari grain order item.
-- - Payment value tidak dijumlahkan berulang per item.
-- ============================================================

CREATE OR REPLACE TABLE
  `olist-ecommerce-analytics-1.olist_mart.fact_orders`
PARTITION BY purchase_date
CLUSTER BY order_status, purchase_year_month
AS

WITH order_attributes AS (
    SELECT
        order_id,
        customer_id,
        customer_unique_id,
        customer_zip_code_prefix,

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

        primary_payment_type,
        max_installments,
        used_voucher,
        is_split_payment,
        total_payment_value,

        review_score,
        review_sentiment,
        review_score_label,
        review_has_comment

    FROM `olist-ecommerce-analytics-1.olist_intermediate.int_order_details`

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY order_id
        ORDER BY order_item_id
    ) = 1
),

order_item_metrics AS (
    SELECT
        order_id,

        -- FINANCIAL MEASURES
        COUNT(*) AS item_count,

        ROUND(SUM(price), 2) AS total_price,

        ROUND(SUM(freight_value), 2)
            AS total_freight_value,

        ROUND(SUM(item_gmv), 2)
            AS total_gmv,

        -- ORDER COMPOSITION
        COUNT(DISTINCT seller_id)
            AS unique_sellers_in_order,

        COUNT(DISTINCT product_id)
            AS unique_products_in_order,

        COUNT(DISTINCT product_category_name_english)
            AS unique_categories_in_order

    FROM `olist-ecommerce-analytics-1.olist_intermediate.int_order_details`
    GROUP BY order_id
),

order_base AS (
    SELECT
        a.*,

        m.item_count,
        m.total_price,
        m.total_freight_value,
        m.total_gmv,
        m.unique_sellers_in_order,
        m.unique_products_in_order,
        m.unique_categories_in_order

    FROM order_attributes a
    INNER JOIN order_item_metrics m
        ON a.order_id = m.order_id
)

SELECT
    ob.order_id,

    ob.customer_id,
    ob.customer_unique_id,
    ob.customer_zip_code_prefix,

    ob.order_status,
    ob.is_revenue_generating,
    ob.is_delivered,
    ob.is_shipped,
    ob.is_approved,
    ob.is_ontime_delivery,
    ob.is_order_date_anomaly,

    ob.order_purchase_timestamp,
    ob.order_approved_at,
    ob.order_delivered_carrier_date,
    ob.order_delivered_customer_date,
    ob.order_estimated_delivery_date,

    ob.purchase_date,
    ob.purchase_year,
    ob.purchase_month,
    ob.purchase_day,
    ob.purchase_day_of_week,
    ob.purchase_year_month,
    ob.purchase_year_quarter,

    ob.purchase_to_delivery_days,
    ob.delivery_vs_estimated_days,
    ob.purchase_to_approved_hours,

    ob.primary_payment_type,
    ob.max_installments,
    ob.used_voucher,
    ob.is_split_payment,
    ob.total_payment_value,

    ob.review_score,
    ob.review_sentiment,
    ob.review_score_label,
    ob.review_has_comment,

    ob.item_count,
    ob.total_price,
    ob.total_freight_value,
    ob.total_gmv,

    ob.unique_sellers_in_order,
    ob.unique_products_in_order,
    ob.unique_categories_in_order,

    -- ORDER VALUE SEGMENTATION
    CASE
        WHEN ob.total_gmv IS NULL THEN 'Unknown'
        WHEN ob.total_gmv < 50 THEN '< R$50'
        WHEN ob.total_gmv < 100 THEN 'R$50-100'
        WHEN ob.total_gmv < 200 THEN 'R$100-200'
        WHEN ob.total_gmv < 500 THEN 'R$200-500'
        WHEN ob.total_gmv < 1000 THEN 'R$500-1000'
        ELSE 'R$1000+'
    END AS order_value_bucket,

    -- CUSTOMER TYPE
    CASE
        WHEN dc.customer_unique_id IS NULL
            THEN 'Unknown'
        WHEN dc.first_purchase_date IS NULL
            THEN 'Unknown'
        WHEN ob.purchase_date IS NULL
            THEN 'Unknown'
        WHEN ob.purchase_date = dc.first_purchase_date
            THEN 'New Customer'
        WHEN ob.purchase_date > dc.first_purchase_date
            THEN 'Returning Customer'
        ELSE 'Unknown'
    END AS customer_type,

    dc.rfm_segment,
    dc.clv_tier

FROM order_base ob

LEFT JOIN `olist-ecommerce-analytics-1.olist_intermediate.int_customers_metrics` dc
    ON ob.customer_unique_id = dc.customer_unique_id;
