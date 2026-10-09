-- ============================================================
-- TABLE: olist_mart.dim_customers
-- PURPOSE:
--   Customer descriptive dimension
--
-- GRAIN:
--   1 row per customer_unique_id
--
-- DESIGN:
--   No aggregated purchase metrics or RFM scores.
--   Customer metrics remain in int_customer_metrics.
-- ============================================================

CREATE OR REPLACE TABLE
  `olist-ecommerce-analytics-1.olist_mart.dim_customers`

CLUSTER BY customer_state

AS

WITH customer_profile AS (

    SELECT
        customer_unique_id,
        customer_zip_code_prefix,
        customer_city,
        customer_state,
        customer_region,

        ROW_NUMBER() OVER (
            PARTITION BY customer_unique_id
            ORDER BY customer_id DESC
        ) AS rn

    FROM
        `olist-ecommerce-analytics-1.olist_staging.stg_customers`

)

SELECT
    -- Customer key
    cp.customer_unique_id,

    -- Geographic attributes
    cp.customer_zip_code_prefix,
    cp.customer_city,
    cp.customer_state,
    cp.customer_region,

    -- Enriched geographic attributes
    geo.state_name AS customer_state_name,
    geo.latitude AS customer_latitude,
    geo.longitude AS customer_longitude

FROM customer_profile AS cp

LEFT JOIN
    `olist-ecommerce-analytics-1.olist_mart.dim_geography` AS geo
    ON cp.customer_zip_code_prefix = geo.zip_code_prefix

WHERE cp.rn = 1;

