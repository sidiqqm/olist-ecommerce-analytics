-- TABLE: olist_reporting.rpt_customer_cohort
-- PURPOSE: Monthly customer cohort retention analysis
-- GRAIN: 1 row per cohort_month x period_number
-- COHORT: First revenue-generating purchase month
-- RETENTION: Active customers / original cohort size

CREATE OR REPLACE TABLE
    `olist-ecommerce-analytics-1.olist_reporting.rpt_customer_cohort`
AS

WITH

-- 1. CUSTOMER COHORT
-- GRAIN: 1 row per customer_unique_id
customer_cohort AS (
    SELECT
        customer_unique_id,

        MIN(purchase_date) AS first_purchase_date,

        DATE_TRUNC(
            MIN(purchase_date),
            MONTH
        ) AS cohort_month

    FROM `olist-ecommerce-analytics-1.olist_mart.fact_orders`

    WHERE is_revenue_generating IS TRUE
      AND customer_unique_id IS NOT NULL
      AND purchase_date IS NOT NULL

    GROUP BY customer_unique_id
),

-- 2. CUSTOMER ACTIVITY
-- GRAIN: 1 row per customer x activity month

customer_activity AS (
    SELECT DISTINCT
        fo.customer_unique_id,

        cc.cohort_month,

        DATE_TRUNC(
            fo.purchase_date,
            MONTH
        ) AS activity_month,

        DATE_DIFF(
            DATE_TRUNC(fo.purchase_date, MONTH),
            cc.cohort_month,
            MONTH
        ) AS period_number

    FROM `olist-ecommerce-analytics-1.olist_mart.fact_orders` AS fo

    INNER JOIN customer_cohort AS cc
        ON fo.customer_unique_id = cc.customer_unique_id

    WHERE fo.is_revenue_generating IS TRUE
      AND fo.customer_unique_id IS NOT NULL
      AND fo.purchase_date IS NOT NULL
),


-- 3. COHORT SIZE
-- GRAIN: 1 row per cohort_month
cohort_size AS (
    SELECT
        cohort_month,
        COUNT(*) AS cohort_size
    FROM customer_cohort
    GROUP BY cohort_month
),

-- 4. ACTIVE CUSTOMERS
-- GRAIN: 1 row per cohort_month x period_number
cohort_retention AS (
    SELECT
        cohort_month,
        period_number,
        COUNT(*) AS active_customers
    FROM (
        SELECT DISTINCT
            cohort_month,
            period_number,
            customer_unique_id
        FROM customer_activity
    )
    GROUP BY
        cohort_month,
        period_number
),

-- 5. REPORTING HORIZON
reporting_horizon AS (
    SELECT
        MAX(DATE_TRUNC(purchase_date, MONTH))
            AS max_activity_month
    FROM `olist-ecommerce-analytics-1.olist_mart.fact_orders`
    WHERE is_revenue_generating IS TRUE
      AND purchase_date IS NOT NULL
),

-- 6. GENERATE ALL OBSERVABLE COHORT PERIODS
cohort_periods AS (
    SELECT
        cs.cohort_month,
        cs.cohort_size,
        period_number,

        DATE_ADD(
            cs.cohort_month,
            INTERVAL period_number MONTH
        ) AS activity_month

    FROM cohort_size AS cs
    CROSS JOIN reporting_horizon AS rh

    CROSS JOIN UNNEST(
        GENERATE_ARRAY(
            0,
            DATE_DIFF(
                rh.max_activity_month,
                cs.cohort_month,
                MONTH
            )
        )
    ) AS period_number
)

-- 7. FINAL REPORT

SELECT
    cp.cohort_month,
    cp.activity_month,
    cp.period_number,
    cp.cohort_size,

    COALESCE(
        cr.active_customers,
        0
    ) AS active_customers,

    ROUND(
        SAFE_DIVIDE(
            COALESCE(cr.active_customers, 0) * 100.0,
            cp.cohort_size
        ),
        2
    ) AS retention_rate_pct

FROM cohort_periods AS cp

LEFT JOIN cohort_retention AS cr
    ON cp.cohort_month = cr.cohort_month
   AND cp.period_number = cr.period_number

ORDER BY
    cp.cohort_month,
    cp.period_number;

-- Tujuan : retention_pct yang berarti butuh active_customers, activity_month,
--  dan cohort_size sebagai denominator

-- 1. buat base customer cohort yang akan digunakan di seluruh subquery
-- 2. customer_activity: cari active month dan periode bulan
-- 3. cohort size : cari jumlah customer pada periode bulan tersebut