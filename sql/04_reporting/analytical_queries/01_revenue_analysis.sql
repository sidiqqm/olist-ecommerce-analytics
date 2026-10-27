-- QUERY 1.1: GMV & ORDER VOLUME TREND
-- PURPOSE:
--   Analyze monthly GMV, order volume, and potential anomalies

-- BASELINE:
--   Current and previous month each have >= 1,000 orders
--   Previous GMV must be > 0

-- ANOMALY METHOD:
--   Robust z-score using Median Absolute Deviation (MAD)

WITH monthly_base AS (
    SELECT
        year_month,
        year_actual,
        month_actual,
        total_orders,
        total_gmv,
        aov,
        gmv_3m_moving_avg,
        cumulative_gmv
    FROM `olist-ecommerce-analytics-1.olist_reporting.rpt_revenue_monthly`
),

monthly_growth AS (
    SELECT
        *,

        LAG(total_orders) OVER (
            ORDER BY year_month
        ) AS prev_month_orders,

        LAG(total_gmv) OVER (
            ORDER BY year_month
        ) AS prev_month_gmv

    FROM monthly_base
),

growth_metrics AS (
    SELECT
        *,

        ROUND(
            SAFE_DIVIDE(
                total_gmv - prev_month_gmv,
                prev_month_gmv
            ) * 100,
            2
        ) AS gmv_mom_growth_pct,

        ROUND(
            SAFE_DIVIDE(
                total_orders - prev_month_orders,
                prev_month_orders
            ) * 100,
            2
        ) AS orders_mom_growth_pct,

        CASE
            WHEN prev_month_gmv IS NULL
                THEN 'No Previous Month'

            WHEN prev_month_gmv = 0
                THEN 'Zero Previous GMV'

            WHEN prev_month_orders < 1000
                THEN 'Low Previous Volume'

            WHEN total_orders < 1000
                THEN 'Low Current Volume'

            ELSE 'Eligible'
        END AS baseline_status

    FROM monthly_growth
),

baseline AS (
    SELECT
        APPROX_QUANTILES(
            gmv_mom_growth_pct, 100
        )[OFFSET(50)] AS median_growth

    FROM growth_metrics

    WHERE baseline_status = 'Eligible'
      AND gmv_mom_growth_pct IS NOT NULL
),

absolute_deviations AS (
    SELECT
        gm.year_month,
        ABS(
            gm.gmv_mom_growth_pct - b.median_growth
        ) AS abs_deviation

    FROM growth_metrics gm
    CROSS JOIN baseline b

    WHERE gm.baseline_status = 'Eligible'
      AND gm.gmv_mom_growth_pct IS NOT NULL
),

mad_stats AS (
    SELECT
        APPROX_QUANTILES(
            abs_deviation, 100
        )[OFFSET(50)] AS mad

    FROM absolute_deviations
),

final_analysis AS (
    SELECT
        gm.*,
        b.median_growth,
        m.mad,

        SAFE_DIVIDE(
            gm.gmv_mom_growth_pct - b.median_growth,
            1.4826 * m.mad
        ) AS robust_z_score

    FROM growth_metrics gm
    CROSS JOIN baseline b
    CROSS JOIN mad_stats m
)

SELECT
    year_month,
    year_actual,
    month_actual,

    total_orders,
    total_gmv,
    aov,

    prev_month_orders,
    prev_month_gmv,
    gmv_mom_growth_pct,
    orders_mom_growth_pct,

    gmv_3m_moving_avg,
    cumulative_gmv,

    baseline_status,
    median_growth,
    mad,
    ROUND(robust_z_score, 2) AS robust_z_score,

    CASE
        WHEN baseline_status != 'Eligible'
            THEN 'Not Evaluated'

        WHEN mad IS NULL OR mad = 0
            THEN 'Cannot Classify'

        WHEN ABS(robust_z_score) > 3
            THEN 'Potential Anomaly'

        ELSE 'Normal'
    END AS month_type

FROM final_analysis
ORDER BY year_month;


-- QUERY 1.2: AOV TREND & DISTRIBUTION
-- GRAIN: 1 row per purchase_year_month

WITH order_base AS (
    SELECT
        order_id,
        purchase_year_month AS year_month,
        purchase_year AS year_actual,
        total_gmv
    FROM `olist-ecommerce-analytics-1.olist_mart.fact_orders`
    WHERE is_revenue_generating = TRUE
      AND total_gmv IS NOT NULL
),

aov_analysis AS (
    SELECT
        year_month,
        year_actual,

        COUNT(DISTINCT order_id) AS total_orders,

        ROUND(AVG(total_gmv), 2) AS avg_order_value,

        ROUND(
            APPROX_QUANTILES(total_gmv, 100)[OFFSET(50)],
            2
        ) AS median_order_value,

        ROUND(
            APPROX_QUANTILES(total_gmv, 100)[OFFSET(25)],
            2
        ) AS p25_order_value,

        ROUND(
            APPROX_QUANTILES(total_gmv, 100)[OFFSET(75)],
            2
        ) AS p75_order_value,

        ROUND(
            APPROX_QUANTILES(total_gmv, 100)[OFFSET(90)],
            2
        ) AS p90_order_value,

        COUNTIF(total_gmv < 50) AS orders_under_50,

        COUNTIF(
            total_gmv >= 50 AND total_gmv < 100
        ) AS orders_50_100,

        COUNTIF(
            total_gmv >= 100 AND total_gmv < 200
        ) AS orders_100_200,

        COUNTIF(
            total_gmv >= 200 AND total_gmv < 500
        ) AS orders_200_500,

        COUNTIF(total_gmv >= 500) AS orders_over_500

    FROM order_base
    GROUP BY year_month, year_actual
),

with_previous_month AS (
    SELECT
        *,
        LAG(avg_order_value) OVER (
            ORDER BY year_month
        ) AS prev_month_aov
    FROM aov_analysis
)

SELECT
    *,
    ROUND(
        SAFE_DIVIDE(
            avg_order_value - prev_month_aov,
            prev_month_aov
        ) * 100,
        2
    ) AS aov_mom_change_pct

FROM with_previous_month
ORDER BY year_month;


-- QUERY 1.3: PAYMENT METHOD ANALYSIS
-- GRAIN: 1 row per year_month x primary_payment_type
WITH payment_summary AS (
    SELECT
        purchase_year_month AS year_month,
        purchase_year AS year_actual,
        primary_payment_type,

        COUNT(DISTINCT order_id) AS order_count,

        ROUND(SUM(total_gmv), 2) AS total_gmv,

        ROUND(AVG(total_gmv), 2) AS avg_order_value,

        ROUND(AVG(max_installments), 2) AS avg_installments,

        COUNTIF(max_installments > 1) AS installment_orders,

        COUNTIF(used_voucher = TRUE) AS voucher_used_orders

    FROM `olist-ecommerce-analytics-1.olist_mart.fact_orders`

    WHERE is_revenue_generating = TRUE
      AND primary_payment_type IS NOT NULL

    GROUP BY
        year_month,
        year_actual,
        primary_payment_type
),

with_pct AS (
    SELECT
        *,

        SUM(order_count) OVER (
            PARTITION BY year_month
        ) AS monthly_orders_by_payment,

        ROUND(
            SAFE_DIVIDE(
                order_count,
                SUM(order_count) OVER (
                    PARTITION BY year_month
                )
            ) * 100,
            2
        ) AS pct_of_month_orders,

        ROUND(
            SAFE_DIVIDE(
                installment_orders,
                order_count
            ) * 100,
            2
        ) AS installment_rate_pct,

        ROUND(
            SAFE_DIVIDE(
                voucher_used_orders,
                order_count
            ) * 100,
            2
        ) AS voucher_usage_rate_pct

    FROM payment_summary
)

SELECT *
FROM with_pct
ORDER BY year_month, order_count DESC;


-- QUERY 1.4: REVENUE BY STATE
-- GRAIN: 1 row per customer_state x year_actual
WITH customer_base AS (
    SELECT
        customer_unique_id,
        customer_state,
        customer_region
    FROM `olist-ecommerce-analytics-1.olist_mart.dim_customers`
),

state_revenue AS (
    SELECT
        c.customer_state,
        c.customer_region,
        f.purchase_year AS year_actual,

        COUNT(DISTINCT f.order_id) AS total_orders,

        COUNT(DISTINCT f.customer_unique_id)
            AS unique_customers,

        ROUND(SUM(f.total_gmv), 2) AS total_gmv,

        ROUND(AVG(f.total_gmv), 2) AS aov,

        ROUND(AVG(f.review_score), 2) AS avg_review_score

    FROM `olist-ecommerce-analytics-1.olist_mart.fact_orders` f

    INNER JOIN customer_base c
        ON f.customer_unique_id = c.customer_unique_id

    WHERE f.is_revenue_generating = TRUE
      AND c.customer_state IS NOT NULL

    GROUP BY
        c.customer_state,
        c.customer_region,
        f.purchase_year
),

ranked_state AS (
    SELECT
        *,

        RANK() OVER (
            PARTITION BY year_actual
            ORDER BY total_gmv DESC
        ) AS revenue_rank

    FROM state_revenue
)

SELECT
    *,
    revenue_rank <= 5 AS is_top5_state
FROM ranked_state
ORDER BY year_actual, total_gmv DESC;