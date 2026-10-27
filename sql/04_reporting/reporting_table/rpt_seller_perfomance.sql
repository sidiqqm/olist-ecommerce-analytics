
CREATE OR REPLACE TABLE
    `olist-ecommerce-analytics-1.olist_reporting.rpt_seller_performance`
CLUSTER BY seller_tier, seller_state
AS

WITH

-- GRAIN: 1 row per seller_id + order_id
seller_review_base AS (
    SELECT
        seller_id,
        order_id,
        review_score
    FROM `olist-ecommerce-analytics-1.olist_mart.fact_order_items`
    WHERE is_revenue_generating IS TRUE

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY seller_id, order_id
        ORDER BY order_item_id
    ) = 1
),


-- GRAIN: 1 row per seller_id
seller_review_metrics AS (
    SELECT
        seller_id,

        ROUND(AVG(review_score), 3) AS avg_review_score,

        COUNTIF(review_score <= 2) AS negative_review_count,

        COUNTIF(review_score IS NOT NULL) AS total_reviews

    FROM seller_review_base
    GROUP BY seller_id
),


-- GRAIN: 1 row per seller_id
seller_activity AS (
    SELECT
        seller_id,

        COUNT(
            DISTINCT DATE_TRUNC(purchase_date, MONTH)
        ) AS active_months

    FROM `olist-ecommerce-analytics-1.olist_intermediate.int_order_details`
    WHERE is_revenue_generating IS TRUE
    GROUP BY seller_id
),

-- GRAIN: 1 row per seller_id
seller_report_base AS (
    SELECT
        sm.seller_id,

        sm.total_orders,
        sm.total_items_sold,
        sm.unique_products,
        sm.unique_customers,

        sm.total_revenue,
        sm.total_gmv,
        sm.avg_item_price,

        sm.avg_delivery_days,
        sm.seller_otdr_pct,

        sm.first_sale_date,
        sm.last_sale_date,

        sm.seller_tier,
        sm.is_active_seller,

        COALESCE(sa.active_months, 0) AS active_months,

        rm.avg_review_score,
        COALESCE(rm.negative_review_count, 0)
            AS negative_review_count,
        COALESCE(rm.total_reviews, 0)
            AS total_reviews

    FROM `olist-ecommerce-analytics-1.olist_intermediate.int_sellers_metrics` AS sm

    LEFT JOIN seller_activity AS sa
        ON sm.seller_id = sa.seller_id

    LEFT JOIN seller_review_metrics AS rm
        ON sm.seller_id = rm.seller_id
),


-- Ranking berdasarkan total GMV
seller_ranked AS (
    SELECT
        *,

        RANK() OVER (
            ORDER BY total_gmv DESC
        ) AS revenue_rank,

        ROUND(
            SAFE_DIVIDE(
                SUM(total_gmv) OVER (
                    ORDER BY total_gmv DESC, seller_id
                    ROWS BETWEEN UNBOUNDED PRECEDING
                    AND CURRENT ROW
                ),
                SUM(total_gmv) OVER ()
            ) * 100,
            2
        ) AS cumulative_gmv_pct

    FROM seller_report_base
)

-- 1 row per seller_id
SELECT
    sr.seller_id,

    sr.total_orders,
    sr.total_items_sold,
    sr.unique_products,
    sr.unique_customers,
    ROUND(sr.total_revenue, 2) AS total_revenue,
    ROUND(sr.total_gmv, 2) AS total_gmv,
    sr.avg_item_price,

    sr.avg_review_score,
    sr.negative_review_count,
    sr.total_reviews,

    sr.seller_otdr_pct,
    sr.avg_delivery_days,

    sr.active_months,
    sr.first_sale_date,
    sr.last_sale_date,
    sr.is_active_seller,

    sr.revenue_rank,
    sr.cumulative_gmv_pct,

    ds.seller_city,
    ds.seller_state,
    ds.seller_region,
    ds.seller_state_name,
    ds.seller_latitude,
    ds.seller_longitude,
    ds.is_sao_paulo_seller,

    sr.seller_tier,

    CASE
        WHEN sr.avg_review_score IS NULL
          OR sr.seller_otdr_pct IS NULL
        THEN NULL

        ELSE ROUND(
            LEAST(
                GREATEST(sr.avg_review_score / 5.0, 0),
                1
            ) * 40

            + LEAST(
                GREATEST(sr.seller_otdr_pct / 100.0, 0),
                1
            ) * 40

            + LEAST(
                GREATEST(sr.active_months / 24.0, 0),
                1
            ) * 20,

            1
        )
    END AS performance_score

FROM seller_ranked AS sr

LEFT JOIN `olist-ecommerce-analytics-1.olist_mart.dim_sellers` AS ds
    ON sr.seller_id = ds.seller_id;