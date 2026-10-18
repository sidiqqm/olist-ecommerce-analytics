

-- QUERY 2.1: New vs Returning Customer Trend
--   BQ-04: New vs Returning customer
-- GRAIN: 1 row per purchase_year_month

WITH monthly_customer_type AS (
    SELECT
        purchase_year_month AS year_month,
        customer_type,

        COUNT(DISTINCT order_id) AS order_count,
        COUNT(DISTINCT customer_unique_id) AS customer_count,
        SUM(total_gmv) AS total_gmv

    FROM `olist-ecommerce-analytics-1.olist_mart.fact_orders`
    WHERE is_revenue_generating = TRUE
      AND customer_type IN ('New Customer', 'Returning Customer')
    GROUP BY
        purchase_year_month,
        customer_type
),

monthly_pivot AS (
    SELECT
        year_month,

        SUM(IF(customer_type = 'New Customer',
               order_count, 0)) AS new_customer_orders,

        SUM(IF(customer_type = 'Returning Customer',
               order_count, 0)) AS returning_customer_orders,

        SUM(IF(customer_type = 'New Customer',
               customer_count, 0)) AS new_customers,

        SUM(IF(customer_type = 'Returning Customer',
               customer_count, 0)) AS returning_customers,

        SUM(IF(customer_type = 'New Customer',
               total_gmv, 0)) AS new_customer_gmv,

        SUM(IF(customer_type = 'Returning Customer',
               total_gmv, 0)) AS returning_customer_gmv

    FROM monthly_customer_type
    GROUP BY year_month
)

SELECT
    year_month,

    new_customer_orders,
    returning_customer_orders,
    new_customers,
    returning_customers,

    new_customers + returning_customers AS total_monthly_customers,

    ROUND(new_customer_gmv, 2) AS new_customer_gmv,
    ROUND(returning_customer_gmv, 2) AS returning_customer_gmv,

    ROUND(
        100.0 * SAFE_DIVIDE(
            returning_customers,
            new_customers + returning_customers
        ),
        2
    ) AS returning_customer_share_pct,

    ROUND(
        100.0 * SAFE_DIVIDE(
            returning_customer_orders,
            new_customer_orders + returning_customer_orders
        ),
        2
    ) AS returning_order_share_pct,

    ROUND(
        100.0 * SAFE_DIVIDE(
            returning_customer_gmv,
            new_customer_gmv + returning_customer_gmv
        ),
        2
    ) AS returning_gmv_share_pct,

    ROUND(
        SAFE_DIVIDE(new_customer_gmv, new_customer_orders),
        2
    ) AS new_customer_order_value,

    ROUND(
        SAFE_DIVIDE(returning_customer_gmv, returning_customer_orders),
        2
    ) AS returning_customer_order_value

FROM monthly_pivot
ORDER BY year_month;

-- QUERY 2.2A: Customer Lifetime Value Distribution
-- BQ-05
-- GRAIN: 1 row per clv_tier x rfm_segment
SELECT
    clv_tier,
    rfm_segment,

    COUNT(*) AS customer_count,

    ROUND(AVG(total_clv), 2) AS avg_clv,

    ROUND(
        APPROX_QUANTILES(total_clv, 100)[OFFSET(50)],
        2
    ) AS median_clv,

    ROUND(
        APPROX_QUANTILES(total_clv, 100)[OFFSET(25)],
        2
    ) AS p25_clv,

    ROUND(
        APPROX_QUANTILES(total_clv, 100)[OFFSET(75)],
        2
    ) AS p75_clv,

    ROUND(MIN(total_clv), 2) AS min_clv,
    ROUND(MAX(total_clv), 2) AS max_clv,

    ROUND(SUM(total_clv), 2) AS total_clv_contribution,

    ROUND(AVG(total_orders), 2) AS avg_orders,
    ROUND(AVG(recency_days), 0) AS avg_recency_days

FROM `olist-ecommerce-analytics-1.olist_intermediate.int_customer_metrics`
GROUP BY
    clv_tier,
    rfm_segment
ORDER BY
    avg_clv DESC;


-- QUERY 2.2B: Customer CLV Pareto Analysis
-- GRAIN: 1 row per selected customer rank

WITH customer_ranked AS (
    SELECT
        customer_unique_id,
        total_clv,

        ROW_NUMBER() OVER (
            ORDER BY total_clv DESC, customer_unique_id
        ) AS clv_rank,

        COUNT(*) OVER () AS total_customers,

        SUM(total_clv) OVER (
            ORDER BY total_clv DESC, customer_unique_id
            ROWS BETWEEN UNBOUNDED PRECEDING
                     AND CURRENT ROW
        ) AS cumulative_clv,

        SUM(total_clv) OVER () AS grand_total_clv

    FROM `olist-ecommerce-analytics-1.olist_intermediate.int_customer_metrics`
    WHERE total_clv IS NOT NULL
      AND total_clv >= 0
),

pareto_points AS (
    SELECT
        *,
        SAFE_DIVIDE(clv_rank, total_customers)
            AS customer_fraction,

        SAFE_DIVIDE(cumulative_clv, grand_total_clv)
            AS cumulative_clv_fraction

    FROM customer_ranked
)

SELECT
    clv_rank,
    total_customers,

    ROUND(customer_fraction * 100, 2)
        AS pct_of_customers,

    ROUND(cumulative_clv, 2)
        AS cumulative_clv,

    ROUND(cumulative_clv_fraction * 100, 2)
        AS pct_of_total_clv

FROM pareto_points

-- Ambil titik saat kumulatif mencapai atau melewati
-- 10%, 20%, 30%, dan seterusnya dari customer base.
WHERE
    clv_rank = 1
    OR CEIL(customer_fraction * 100)
       > CEIL((clv_rank - 1.0) / total_customers * 100)
ORDER BY clv_rank;


-- QUERY 2.3: RFM Segment Analysis
-- BQ-06
-- GRAIN: 1 row per rfm_segment

WITH rfm_summary AS (
    SELECT
        rfm_segment,

        COUNT(*) AS customer_count,

        ROUND(
            100.0 * SAFE_DIVIDE(
                COUNT(*),
                SUM(COUNT(*)) OVER ()
            ),
            2
        ) AS pct_of_customers,

        ROUND(SUM(total_clv), 2) AS total_clv,

        ROUND(
            100.0 * SAFE_DIVIDE(
                SUM(total_clv),
                SUM(SUM(total_clv)) OVER ()
            ),
            2
        ) AS pct_of_total_clv,

        ROUND(AVG(total_clv), 2) AS avg_clv,
        ROUND(AVG(total_orders), 2) AS avg_orders,
        ROUND(AVG(recency_days), 0) AS avg_recency_days,

        ROUND(AVG(r_score), 2) AS avg_r_score,
        ROUND(AVG(f_score), 2) AS avg_f_score,
        ROUND(AVG(m_score), 2) AS avg_m_score

    FROM `olist-ecommerce-analytics-1.olist_intermediate.int_customer_metrics`
    GROUP BY rfm_segment
)

SELECT
    *,

    CASE rfm_segment
        WHEN 'Champions'
            THEN 'Reward loyal customers and encourage referrals'
        WHEN 'Loyal Customers'
            THEN 'Reward loyalty and offer relevant upsells'
        WHEN 'Potential Loyalists'
            THEN 'Encourage repeat purchases and membership'
        WHEN 'Recent Customers'
            THEN 'Support onboarding and encourage a second purchase'
        WHEN 'Promising'
            THEN 'Build engagement with relevant recommendations'
        WHEN 'Need Attention'
            THEN 'Re-engage with relevant offers'
        WHEN 'About to Sleep'
            THEN 'Test targeted reactivation campaigns'
        WHEN 'At Risk'
            THEN 'Prioritize personalized win-back campaigns'
        WHEN 'Hibernating'
            THEN 'Test low-cost reactivation before larger investment'
        ELSE
            'Review segment definition and customer behavior'
    END AS recommended_action

FROM rfm_summary
ORDER BY avg_clv DESC;


-- QUERY 2.4A: Cohort Retention Summary
-- BQ-07
-- GRAIN: 1 row per period_number

WITH cohort_data AS (
    SELECT
        cohort_month,
        period_number,
        cohort_size,
        active_customers,
        retention_rate_pct

    FROM `olist-ecommerce-analytics-1.olist_reporting.rpt_customer_cohort`
    WHERE period_number BETWEEN 0 AND 12
),

avg_retention AS (
    SELECT
        period_number,

        ROUND(AVG(retention_rate_pct), 2)
            AS avg_retention_rate,

        ROUND(
            100.0 * SAFE_DIVIDE(
                SUM(active_customers),
                SUM(cohort_size)
            ),
            2
        ) AS weighted_retention_rate,

        ROUND(MIN(retention_rate_pct), 2)
            AS min_retention_rate,

        ROUND(MAX(retention_rate_pct), 2)
            AS max_retention_rate,

        COUNT(DISTINCT cohort_month)
            AS cohorts_included

    FROM cohort_data
    GROUP BY period_number
)

SELECT *
FROM avg_retention
ORDER BY period_number;

-- QUERY 2.4B: Cohort Retention Detail
-- GRAIN: 1 row per cohort_month x period_number

SELECT
    cohort_month,
    period_number,
    cohort_size,
    active_customers,
    retention_rate_pct

FROM `olist-ecommerce-analytics-1.olist_reporting.rpt_customer_cohort`
WHERE period_number BETWEEN 0 AND 12
ORDER BY
    cohort_month,
    period_number;