
CREATE OR REPLACE TABLE `olist-ecommerce-analytics-1.olist_intermediate.int_sellers_metrics` AS

WITH base_items AS (
    SELECT
        seller_id,
        order_id,
        product_id,
        order_item_id,
        customer_unique_id,
        purchase_date,
        price,
        freight_value,
        item_gmv,
        order_delivered_customer_date,
        purchase_to_approved_hours,
        purchase_to_delivery_days,
        is_ontime_delivery,
        is_order_date_anomaly
    FROM `olist-ecommerce-analytics-1.olist_intermediate.int_order_details`
    WHERE is_revenue_generating = TRUE
),

seller_orders AS (
    SELECT
        seller_id,
        order_id,
        customer_unique_id,
        purchase_date,
        order_delivered_customer_date,
        purchase_to_approved_hours,
        purchase_to_delivery_days,
        is_ontime_delivery,
        is_order_date_anomaly
    FROM base_items
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY seller_id, order_id
        ORDER BY order_item_id
    ) = 1
),

seller_order_metrics AS (
    SELECT
        seller_id,
        COUNT(*) AS total_orders,
        COUNT(DISTINCT customer_unique_id) AS unique_customers,

        ROUND(
            AVG(
                CASE
                    WHEN order_delivered_customer_date IS NOT NULL
                        AND is_order_date_anomaly IS NOT TRUE
                    THEN purchase_to_delivery_days
                END
            ),
            1
        ) AS avg_purchase_to_delivery_days,

        ROUND(
            SAFE_DIVIDE(
                COUNTIF(is_ontime_delivery IS TRUE) * 100.0,
                COUNTIF(is_ontime_delivery IS NOT NULL)
            ),
            2
        ) AS seller_otdr_pct

    FROM seller_orders
    GROUP BY seller_id
),

seller_item_metrics AS (
    SELECT
        seller_id,
        COUNT(*) AS total_items_sold,
        COUNT(DISTINCT product_id) AS unique_products,

        ROUND(SUM(price), 2) AS total_revenue,
        ROUND(SUM(item_gmv), 2) AS total_gmv,
        ROUND(AVG(price), 2) AS avg_item_price,

        MIN(purchase_date) AS first_order_date,
        MAX(purchase_date) AS last_order_date

    FROM base_items
    GROUP BY seller_id
),

seller_metrics AS (
    SELECT
        so.seller_id,

        so.total_orders,
        so.unique_customers,

        si.total_items_sold,
        si.unique_products,

        si.total_revenue,
        si.total_gmv,
        si.avg_item_price,

        si.first_order_date,
        si.last_order_date,

        so.avg_purchase_to_delivery_days,
        so.seller_otdr_pct

    FROM seller_order_metrics AS so
    INNER JOIN seller_item_metrics AS si
        ON so.seller_id = si.seller_id
),

seller_ranked AS (
    SELECT
        seller_id,

        total_orders,
        unique_customers,

        total_items_sold,
        unique_products,

        total_revenue,
        total_gmv,
        avg_item_price,

        first_order_date,
        last_order_date,

        avg_purchase_to_delivery_days,
        seller_otdr_pct,

        PERCENT_RANK() OVER (
            ORDER BY total_revenue ASC
        ) AS revenue_percentile,

        RANK() OVER (
            ORDER BY total_orders DESC
        ) AS order_rank

    FROM seller_metrics
)

SELECT
    s.seller_id,

    COALESCE(sr.total_orders, 0) AS total_orders,
    COALESCE(sr.total_items_sold, 0) AS total_items_sold,
    COALESCE(sr.unique_products, 0) AS unique_products,
    COALESCE(sr.unique_customers, 0) AS unique_customers,

    COALESCE(sr.total_revenue, 0) AS total_revenue,
    COALESCE(sr.total_gmv, 0) AS total_gmv,

    sr.avg_item_price,
    sr.avg_purchase_to_delivery_days AS avg_delivery_days,
    sr.seller_otdr_pct,

    sr.first_order_date AS first_sale_date,
    sr.last_order_date AS last_sale_date,

    CASE
        WHEN sr.seller_id IS NULL
            THEN 'Inactive'
        WHEN sr.revenue_percentile >= 0.8
            THEN 'Platinum'
        WHEN sr.revenue_percentile >= 0.6
            THEN 'Gold'
        WHEN sr.revenue_percentile >= 0.4
            THEN 'Silver'
        ELSE 'Bronze'
    END AS seller_tier,

    sr.seller_id IS NOT NULL AS is_active_seller

FROM `olist-ecommerce-analytics-1.olist_staging.stg_sellers` AS s
LEFT JOIN seller_ranked AS sr
    ON s.seller_id = sr.seller_id;