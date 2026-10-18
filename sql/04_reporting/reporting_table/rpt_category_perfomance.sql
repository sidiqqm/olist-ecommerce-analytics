
-- TABLE: olist_reporting.rpt_category_performance
-- PURPOSE: Monthly product category performance

-- GRAIN: 1 row per product category x calendar month

CREATE OR REPLACE TABLE
    `olist-ecommerce-analytics-1.olist_reporting.rpt_category_performance`
CLUSTER BY product_category_name_english, year_month
AS

WITH

-- 1. BASE ITEMS
-- GRAIN: 1 row per order item
base_items AS (
    SELECT
        order_id,
        order_item_id,
        product_category_name_english,
        product_super_category,
        seller_id,
        customer_unique_id,
        purchase_date,
        DATE_TRUNC(purchase_date, MONTH) AS month_start,
        price,
        item_gmv,
        review_score,
        is_delivered,
        is_order_date_anomaly,
        purchase_to_delivery_days

    FROM `olist-ecommerce-analytics-1.olist_mart.fact_order_items`

    WHERE is_revenue_generating IS TRUE
      AND product_category_name_english IS NOT NULL
      AND purchase_date IS NOT NULL
),

-- 2. CATEGORY DIMENSION
-- GRAIN: 1 row per product category
category_list AS (
    SELECT
        product_category_name_english,
        ANY_VALUE(product_super_category) AS product_super_category
    FROM base_items
    GROUP BY product_category_name_english
),

-- 3. MONTHLY ITEM METRICS
-- GRAIN: 1 row per category x month
monthly_item_metrics AS (
    SELECT
        product_category_name_english,
        month_start,

        -- COUNT(*) is valid because base_items has item-level grain.
        COUNT(*) AS total_items,

        COUNT(DISTINCT seller_id) AS unique_sellers,

        COUNT(DISTINCT customer_unique_id) AS unique_customers,

        ROUND(SUM(item_gmv), 2) AS total_gmv,

        ROUND(AVG(price), 2) AS avg_price

    FROM base_items
    GROUP BY
        product_category_name_english,
        month_start
),

-- 4. CATEGORY-ORDER BASE
-- GRAIN: 1 row per order x category
-- Prevents repeated order-level review/delivery values.
category_order_base AS (
    SELECT
        order_id,
        product_category_name_english,
        month_start,
        review_score,
        is_delivered,
        is_order_date_anomaly,
        purchase_to_delivery_days

    FROM base_items

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY order_id, product_category_name_english
        ORDER BY order_item_id
    ) = 1
),

-- 5. MONTHLY ORDER METRICS
-- GRAIN: 1 row per category x month
monthly_order_metrics AS (
    SELECT
        product_category_name_english,
        month_start,

        COUNT(*) AS total_orders,

        ROUND(AVG(review_score), 3) AS avg_review_score,

        COUNTIF(review_score <= 2) AS negative_reviews,

        COUNTIF(review_score IS NOT NULL) AS total_reviews,

        ROUND(
            AVG(
                CASE
                    WHEN is_delivered IS TRUE
                     AND is_order_date_anomaly IS NOT TRUE
                     AND purchase_to_delivery_days >= 0
                    THEN purchase_to_delivery_days
                END
            ),
            1
        ) AS avg_delivery_days,

        COUNTIF(
            is_delivered IS TRUE
            AND is_order_date_anomaly IS NOT TRUE
            AND purchase_to_delivery_days >= 0
        ) AS valid_delivery_orders

    FROM category_order_base

    GROUP BY
        product_category_name_english,
        month_start
),

-- 6. MONTH CALENDAR
month_calendar AS (
    SELECT month_start
    FROM UNNEST(
        GENERATE_DATE_ARRAY(
            (SELECT MIN(month_start) FROM base_items),
            (SELECT MAX(month_start) FROM base_items),
            INTERVAL 1 MONTH
        )
    ) AS month_start
),

-- 7. CATEGORY x MONTH SPINE
category_month_spine AS (
    SELECT
        c.product_category_name_english,
        c.product_super_category,
        m.month_start

    FROM category_list AS c
    CROSS JOIN month_calendar AS m
),

-- 8. COMBINE MONTHLY METRICS
monthly_category AS (
    SELECT
        s.product_category_name_english,
        s.product_super_category,
        s.month_start,

        FORMAT_DATE('%Y-%m', s.month_start) AS year_month,
        EXTRACT(YEAR FROM s.month_start) AS year_actual,

        COALESCE(om.total_orders, 0) AS total_orders,
        COALESCE(im.total_items, 0) AS total_items,
        COALESCE(im.unique_sellers, 0) AS unique_sellers,
        COALESCE(im.unique_customers, 0) AS unique_customers,

        COALESCE(im.total_gmv, 0) AS total_gmv,
        im.avg_price,

        om.avg_review_score,
        COALESCE(om.negative_reviews, 0) AS negative_reviews,
        COALESCE(om.total_reviews, 0) AS total_reviews,

        om.avg_delivery_days,
        COALESCE(om.valid_delivery_orders, 0)
            AS valid_delivery_orders

    FROM category_month_spine AS s

    LEFT JOIN monthly_item_metrics AS im
        ON s.product_category_name_english =
           im.product_category_name_english
       AND s.month_start = im.month_start

    LEFT JOIN monthly_order_metrics AS om
        ON s.product_category_name_english =
           om.product_category_name_english
       AND s.month_start = om.month_start
),

-- 9. MONTH-OVER-MONTH COMPARISON AND CATEGORY RANKING
with_growth AS (
    SELECT
        *,

        LAG(total_gmv) OVER (
            PARTITION BY product_category_name_english
            ORDER BY month_start
        ) AS prev_month_gmv,

        RANK() OVER (
            PARTITION BY month_start
            ORDER BY total_gmv DESC
        ) AS monthly_revenue_rank

    FROM monthly_category
)

-- 10. FINAL REPORT
SELECT
    *,

    CASE
        WHEN prev_month_gmv > 0
        THEN ROUND(
            SAFE_DIVIDE(
                total_gmv - prev_month_gmv,
                prev_month_gmv
            ) * 100,
            2
        )
        ELSE NULL
    END AS gmv_mom_growth_pct

FROM with_growth;