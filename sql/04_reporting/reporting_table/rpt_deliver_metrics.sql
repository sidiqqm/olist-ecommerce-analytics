
-- TABLE: olist_reporting.rpt_delivery_metrics
-- PURPOSE: Monthly delivery performance by customer state
-- GRAIN: 1 row per customer_state x year_month

CREATE OR REPLACE TABLE
  `olist-ecommerce-analytics-1.olist_reporting.rpt_delivery_metrics`
CLUSTER BY customer_state, year_month
AS

WITH

-- 1. MAP ORDER TO CUSTOMER STATE
-- GRAIN: 1 row per order_id
order_state_map AS (
    SELECT
        order_id,
        ANY_VALUE(customer_state) AS customer_state
    FROM
        `olist-ecommerce-analytics-1.olist_mart.fact_order_items`
    WHERE customer_state IS NOT NULL
    GROUP BY order_id
    HAVING COUNT(DISTINCT customer_state) = 1
),

-- 2. ORDER BASE
-- GRAIN: 1 row per order_id
order_base AS (
    SELECT
        fo.order_id,
        osm.customer_state,
        fo.purchase_year_month AS year_month,
        fo.purchase_year AS year_actual,

        fo.is_delivered,
        fo.is_order_date_anomaly,
        fo.purchase_to_delivery_days,
        fo.delivery_vs_estimated_days,
        fo.is_ontime_delivery,
        fo.review_score

    FROM
        `olist-ecommerce-analytics-1.olist_mart.fact_orders` fo

    INNER JOIN order_state_map osm
        ON fo.order_id = osm.order_id

    WHERE fo.is_revenue_generating IS TRUE
      AND fo.purchase_year_month IS NOT NULL
),

-- 3. ORDER-LEVEL DELIVERY METRICS
-- SOURCE GRAIN: 1 row per order_id
order_metrics AS (
    SELECT
        customer_state,
        year_month,
        year_actual,

        COUNT(*) AS total_orders,

        COUNTIF(
            is_delivered IS TRUE
            AND is_order_date_anomaly IS NOT TRUE
            AND purchase_to_delivery_days >= 0
            AND is_ontime_delivery IS TRUE
        ) AS on_time_orders,

        COUNTIF(
            is_delivered IS TRUE
            AND is_order_date_anomaly IS NOT TRUE
            AND purchase_to_delivery_days >= 0
            AND is_ontime_delivery IS FALSE
        ) AS late_orders,

        COUNTIF(
            is_delivered IS TRUE
            AND is_order_date_anomaly IS NOT TRUE
            AND purchase_to_delivery_days >= 0
            AND is_ontime_delivery IS NOT NULL
        ) AS eligible_otdr_orders,

        ROUND(
            SAFE_DIVIDE(
                COUNTIF(
                    is_delivered IS TRUE
                    AND is_order_date_anomaly IS NOT TRUE
                    AND purchase_to_delivery_days >= 0
                    AND is_ontime_delivery IS TRUE
                ) * 100.0,
                COUNTIF(
                    is_delivered IS TRUE
                    AND is_order_date_anomaly IS NOT TRUE
                    AND purchase_to_delivery_days >= 0
                    AND is_ontime_delivery IS NOT NULL
                )
            ),
            2
        ) AS otdr_pct,

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

        ROUND(
            AVG(
                CASE
                    WHEN is_delivered IS TRUE
                     AND is_order_date_anomaly IS NOT TRUE
                    THEN delivery_vs_estimated_days
                END
            ),
            1
        ) AS avg_gap_vs_estimate,

        ROUND(AVG(review_score), 3) AS avg_review_score,

        COUNTIF(review_score IS NOT NULL) AS total_reviews

    FROM order_base

    GROUP BY
        customer_state,
        year_month,
        year_actual
),

-- 4. ITEM-LEVEL FREIGHT METRICS
-- SOURCE GRAIN: 1 row per order item
item_metrics AS (
    SELECT
        ob.customer_state,
        ob.year_month,

        COUNT(foi.order_item_id) AS total_items,

        ROUND(
            SUM(foi.freight_value),
            2
        ) AS total_freight_revenue,

        ROUND(
            AVG(foi.freight_value),
            2
        ) AS avg_freight_per_item

    FROM order_base ob

    INNER JOIN
        `olist-ecommerce-analytics-1.olist_mart.fact_order_items` foi
        ON ob.order_id = foi.order_id

    WHERE foi.is_revenue_generating IS TRUE

    GROUP BY
        ob.customer_state,
        ob.year_month
),

-- 5. STATE GEOGRAPHY
-- EXPECTED GRAIN: 1 row per state_code
geo_state AS (
    SELECT
        state_code,
        ANY_VALUE(state_name) AS state_name,
        ANY_VALUE(region) AS region,
        AVG(latitude) AS latitude,
        AVG(longitude) AS longitude

    FROM
        `olist-ecommerce-analytics-1.olist_mart.dim_geography`

    GROUP BY state_code
)

-- 6. FINAL REPORT
-- GRAIN: 1 row per customer_state x year_month
SELECT
    om.customer_state,
    om.year_month,
    om.year_actual,

    om.total_orders,
    om.on_time_orders,
    om.late_orders,
    om.eligible_otdr_orders,
    om.otdr_pct,

    om.avg_delivery_days,
    om.avg_gap_vs_estimate,

    om.avg_review_score,
    om.total_reviews,

    COALESCE(im.total_items, 0) AS total_items,
    COALESCE(im.total_freight_revenue, 0)
        AS total_freight_revenue,
    im.avg_freight_per_item,

    geo.state_name AS customer_state_name,
    geo.region AS customer_region,
    geo.latitude AS state_latitude,
    geo.longitude AS state_longitude

FROM order_metrics om

LEFT JOIN item_metrics im
    ON om.customer_state = im.customer_state
   AND om.year_month = im.year_month

LEFT JOIN geo_state geo
    ON om.customer_state = geo.state_code;
