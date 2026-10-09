
-- ============================================================
-- TABLE: olist_intermediate.int_customer_metrics
-- PURPOSE:
--   Customer-level purchase metrics and RFM segmentation
--
-- GRAIN:
--   1 row per customer_unique_id
--
-- NOTES:
--   total_clv represents historical order value in this model,
--   not necessarily predictive Customer Lifetime Value.
-- ============================================================

CREATE OR REPLACE TABLE
  `olist-ecommerce-analytics-1.olist_intermediate.int_customer_metrics`
AS

WITH order_item_summary AS (

    -- Pastikan item diagregasi menjadi satu baris per order
    SELECT
        order_id,
        SUM(COALESCE(item_gmv, 0)) AS order_gmv,
        SUM(COALESCE(price, 0)) AS order_price_total,
        COUNT(order_item_id) AS item_count_per_order

    FROM
        `olist-ecommerce-analytics-1.olist_intermediate.int_order_items`

    GROUP BY
        order_id

),

customer_orders AS (

    -- Grain: 1 row per order
    SELECT
        c.customer_unique_id,
        o.order_id,
        o.purchase_date,
        o.purchase_year_month,
        o.is_revenue_generating,
        o.is_delivered,
        o.is_ontime_delivery,

        COALESCE(oi.order_gmv, 0) AS order_gmv,
        COALESCE(oi.order_price_total, 0) AS order_price_total,
        COALESCE(oi.item_count_per_order, 0) AS item_count_per_order

    FROM
        `olist-ecommerce-analytics-1.olist_int.int_orders` AS o

    INNER JOIN
        `olist-ecommerce-analytics-1.olist_staging.stg_customers` AS c
        ON o.customer_id = c.customer_id

    LEFT JOIN
        order_item_summary AS oi
        ON o.order_id = oi.order_id

),

reference_date AS (

    -- Tanggal acuan recency dari seluruh pesanan
    SELECT
        MAX(purchase_date) AS analysis_date
    FROM customer_orders

),

customer_summary AS (

    -- Grain: 1 row per customer_unique_id
    SELECT
        co.customer_unique_id,

        -- Frequency
        COUNT(DISTINCT co.order_id) AS total_orders,

        COUNTIF(
            co.is_revenue_generating IS TRUE
        ) AS revenue_generating_orders,

        COUNTIF(
            co.is_delivered IS TRUE
        ) AS delivered_orders,

        -- Purchase dates
        MIN(co.purchase_date) AS first_purchase_date,
        MAX(co.purchase_date) AS last_purchase_date,

        -- Recency
        DATE_DIFF(
            rd.analysis_date,
            MAX(co.purchase_date),
            DAY
        ) AS recency_days,

        -- Monetary
        SUM(
            CASE
                WHEN co.is_revenue_generating IS TRUE
                    THEN co.order_gmv
                ELSE 0
            END
        ) AS total_clv,

        AVG(
            CASE
                WHEN co.is_revenue_generating IS TRUE
                    THEN co.order_gmv
            END
        ) AS avg_order_value,

        MAX(
            CASE
                WHEN co.is_revenue_generating IS TRUE
                    THEN co.order_gmv
            END
        ) AS max_order_value,

        -- Customer behavior
        COUNTIF(
            co.is_revenue_generating IS TRUE
        ) > 1 AS is_repeat_customer,

        COUNT(
            DISTINCT CASE
                WHEN co.is_revenue_generating IS TRUE
                    THEN co.purchase_year_month
            END
        ) AS active_months

    FROM customer_orders AS co
    CROSS JOIN reference_date AS rd

    GROUP BY
        co.customer_unique_id,
        rd.analysis_date

),

fm_scored AS (

    SELECT
        *,

        -- Recency: semakin kecil recency_days, semakin tinggi skor
        NTILE(5) OVER (
            ORDER BY recency_days DESC
        ) AS r_score,

        -- Frequency: semakin banyak order, semakin tinggi skor
        NTILE(5) OVER (
            ORDER BY revenue_generating_orders ASC
        ) AS f_score,

        -- Monetary: semakin tinggi historical value, semakin tinggi skor
        NTILE(5) OVER (
            ORDER BY total_clv ASC
        ) AS m_score

    FROM customer_summary

),

rfm_scored AS (

    SELECT
        *,

        CONCAT(
            CAST(r_score AS STRING),
            CAST(f_score AS STRING),
            CAST(m_score AS STRING)
        ) AS rfm_score,

        ROUND(
            (r_score + f_score + m_score) / 3.0,
            2
        ) AS rfm_avg_score

    FROM fm_scored

),

rfm_segmented AS (

    SELECT
        *,

        CASE

            WHEN r_score = 5
                AND f_score >= 4
                AND m_score >= 4
                THEN 'Champions'

            -- Diletakkan sebelum Loyal Customers
            WHEN r_score <= 2
                AND f_score >= 4
                AND m_score >= 4
                THEN 'At Risk'

            WHEN f_score >= 4
                AND m_score >= 4
                THEN 'Loyal Customers'

            WHEN r_score >= 4
                AND f_score >= 2
                AND m_score >= 2
                THEN 'Potential Loyalists'

            WHEN r_score >= 4
                AND f_score <= 2
                THEN 'Recent Customers'

            WHEN r_score = 3
                AND f_score >= 3
                AND m_score >= 3
                THEN 'Need Attention'

            WHEN r_score = 3
                AND f_score <= 2
                THEN 'Promising'

            WHEN r_score <= 2
                AND f_score >= 2
                AND m_score >= 2
                THEN 'About to Sleep'

            WHEN r_score <= 2
                AND f_score <= 2
                THEN 'Hibernating'

            ELSE 'Others'

        END AS rfm_segment

    FROM rfm_scored

)

SELECT *
FROM rfm_segmented;