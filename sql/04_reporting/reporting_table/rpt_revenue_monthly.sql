CREATE OR REPLACE TABLE
  `olist-ecommerce-analytics-1.olist_reporting.rpt_revenue_monthly`
AS

WITH eligible_orders AS (

    -- GRAIN: 1 row per order_id
    SELECT
        order_id,
        customer_unique_id,
        purchase_date,
        purchase_year_month,
        purchase_year,
        purchase_month,
        customer_type,
        total_gmv,
        total_price,
        total_freight_value,
        primary_payment_type,
        purchase_to_delivery_days,
        is_ontime_delivery,
        review_score,
        item_count

    FROM `olist-ecommerce-analytics-1.olist_mart.fact_orders`

    WHERE is_revenue_generating IS TRUE
      AND is_order_date_anomaly IS FALSE
),

calendar_bounds AS (
    SELECT
        DATE_TRUNC(MIN(purchase_date), MONTH) AS min_month,
        DATE_TRUNC(MAX(purchase_date), MONTH) AS max_month
    FROM eligible_orders
),

calendar_months AS (
    SELECT
        month_start,
        FORMAT_DATE('%Y-%m', month_start) AS year_month,
        EXTRACT(YEAR FROM month_start) AS year_actual,
        EXTRACT(MONTH FROM month_start) AS month_actual

    FROM calendar_bounds,
    UNNEST(
        GENERATE_DATE_ARRAY(
            min_month,
            max_month,
            INTERVAL 1 MONTH
        )
    ) AS month_start
),

monthly_metrics AS (
    SELECT
        DATE_TRUNC(purchase_date, MONTH) AS month_start,

        COUNT(*) AS total_orders,

        COUNT(DISTINCT customer_unique_id)
            AS unique_customers,

        COUNTIF(customer_type = 'New Customer')
            AS new_customers,

        COUNTIF(customer_type = 'Returning Customer')
            AS returning_customers,

        SUM(total_gmv) AS total_gmv_raw,
        SUM(total_price) AS total_product_revenue_raw,
        SUM(total_freight_value) AS total_freight_revenue_raw,

        COUNTIF(primary_payment_type = 'credit_card')
            AS credit_card_orders,

        COUNTIF(primary_payment_type = 'boleto')
            AS boleto_orders,

        COUNTIF(primary_payment_type = 'voucher')
            AS voucher_orders,

        COUNTIF(primary_payment_type = 'debit_card')
            AS debit_card_orders,

        AVG(
            IF(
                purchase_to_delivery_days >= 0,
                purchase_to_delivery_days,
                NULL
            )
        ) AS avg_delivery_days_raw,

        SAFE_DIVIDE(
            COUNTIF(is_ontime_delivery IS TRUE) * 100.0,
            COUNTIF(is_ontime_delivery IS NOT NULL)
        ) AS otdr_pct_raw,

        AVG(review_score) AS avg_review_score_raw,

        COUNTIF(review_score >= 4) AS positive_reviews,
        COUNTIF(review_score <= 2) AS negative_reviews,
        COUNTIF(review_score IS NOT NULL) AS total_reviews,

        SUM(item_count) AS total_items_sold_raw,
        AVG(item_count) AS avg_items_per_order_raw

    FROM eligible_orders
    GROUP BY DATE_TRUNC(purchase_date, MONTH)
),

monthly_complete AS (
    SELECT
        c.month_start,
        c.year_month,
        c.year_actual,
        c.month_actual,

        COALESCE(m.total_orders, 0) AS total_orders,
        COALESCE(m.unique_customers, 0) AS unique_customers,

        COALESCE(m.new_customers, 0)
            AS new_customers,

        COALESCE(m.returning_customers, 0)
            AS returning_customers,

        COALESCE(m.total_gmv_raw, 0) AS total_gmv_raw,
        COALESCE(m.total_product_revenue_raw, 0)
            AS total_product_revenue_raw,

        COALESCE(m.total_freight_revenue_raw, 0)
            AS total_freight_revenue_raw,

        m.avg_delivery_days_raw,
        m.otdr_pct_raw,

        m.avg_review_score_raw,
        COALESCE(m.positive_reviews, 0) AS positive_reviews,
        COALESCE(m.negative_reviews, 0) AS negative_reviews,
        COALESCE(m.total_reviews, 0) AS total_reviews,

        COALESCE(m.total_items_sold_raw, 0) AS total_items_sold_raw,
        m.avg_items_per_order_raw,

        COALESCE(m.credit_card_orders, 0) AS credit_card_orders,
        COALESCE(m.boleto_orders, 0) AS boleto_orders,
        COALESCE(m.voucher_orders, 0) AS voucher_orders,
        COALESCE(m.debit_card_orders, 0) AS debit_card_orders

    FROM calendar_months c
    LEFT JOIN monthly_metrics m
        ON c.month_start = m.month_start
),

with_growth AS (
    SELECT
        *,

        LAG(total_gmv_raw, 1) OVER (
            ORDER BY month_start
        ) AS prev_month_gmv,

        LAG(total_orders, 1) OVER (
            ORDER BY month_start
        ) AS prev_month_orders,

        LAG(total_gmv_raw, 12) OVER (
            ORDER BY month_start
        ) AS same_month_last_year_gmv,

        LAG(total_orders, 12) OVER (
            ORDER BY month_start
        ) AS same_month_last_year_orders,

        SUM(total_gmv_raw) OVER (
            ORDER BY month_start
            ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
        ) AS cumulative_gmv_raw,

        AVG(total_gmv_raw) OVER (
            ORDER BY month_start
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS gmv_3m_moving_avg_raw

    FROM monthly_complete
)

SELECT
    year_month,
    year_actual,
    month_actual,
    month_start,

    total_orders,
    unique_customers,
    new_customers,
    returning_customers,

    ROUND(total_gmv_raw, 2) AS total_gmv,

    ROUND(total_product_revenue_raw, 2)
        AS total_product_revenue,

    ROUND(total_freight_revenue_raw, 2)
        AS total_freight_revenue,

    ROUND(
        SAFE_DIVIDE(total_gmv_raw, total_orders),
        2
    ) AS aov,

    credit_card_orders,
    boleto_orders,
    voucher_orders,
    debit_card_orders,

    ROUND(avg_delivery_days_raw, 1)
        AS avg_delivery_days,

    ROUND(otdr_pct_raw, 2) AS otdr_pct,

    ROUND(avg_review_score_raw, 3)
        AS avg_review_score,

    positive_reviews,
    negative_reviews,
    total_reviews,

    total_items_sold_raw AS total_items_sold,

    ROUND(avg_items_per_order_raw, 2)
        AS avg_items_per_order,

    prev_month_gmv,
    prev_month_orders,
    same_month_last_year_gmv,
    same_month_last_year_orders,

    CASE
        WHEN prev_month_gmv > 0
        THEN ROUND(
            SAFE_DIVIDE(
                total_gmv_raw - prev_month_gmv,
                prev_month_gmv
            ) * 100,
            2
        )
        ELSE NULL
    END AS gmv_mom_growth_pct,

    CASE
        WHEN prev_month_orders > 0
        THEN ROUND(
            SAFE_DIVIDE(
                total_orders - prev_month_orders,
                prev_month_orders
            ) * 100,
            2
        )
        ELSE NULL
    END AS orders_mom_growth_pct,

    CASE
        WHEN same_month_last_year_gmv > 0
        THEN ROUND(
            SAFE_DIVIDE(
                total_gmv_raw - same_month_last_year_gmv,
                same_month_last_year_gmv
            ) * 100,
            2
        )
        ELSE NULL
    END AS gmv_yoy_growth_pct,

    ROUND(cumulative_gmv_raw, 2) AS cumulative_gmv,

    ROUND(gmv_3m_moving_avg_raw, 2)
        AS gmv_3m_moving_avg

FROM with_growth
ORDER BY month_start;
