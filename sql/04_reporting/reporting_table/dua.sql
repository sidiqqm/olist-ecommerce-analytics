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