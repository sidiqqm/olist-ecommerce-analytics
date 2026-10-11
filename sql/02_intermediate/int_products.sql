sql
CREATE OR REPLACE VIEW
  `olist-ecommerce-analytics-1.olist_intermediate.int_products`
AS

WITH product_base AS (

    -- 1. BASE PRODUCT
    -- GRAIN: 1 row per product_id
    -- PURPOSE: Atribut dan karakteristik dasar produk

    SELECT
        product_id,
        product_category_name,

        product_name_length,
        product_description_length,
        product_photos_qty,

        product_weight_g,
        product_length_cm,
        product_height_cm,
        product_width_cm,

        has_complete_dimensions,
        has_weight,
        has_photos,
        is_unknown_category,

        -- Estimated volumetric weight (kg)
        -- Analytical assumption: divisor 6000
        CASE
            WHEN product_width_cm IS NOT NULL
                AND product_length_cm IS NOT NULL
                AND product_height_cm IS NOT NULL
            THEN ROUND(
                product_width_cm
                * product_length_cm
                * product_height_cm / 6000,
                3
            )
            ELSE NULL
        END AS volumetric_weight_kg,

        -- Actual product weight (kg)
        CASE
            WHEN product_weight_g IS NOT NULL
            THEN ROUND(product_weight_g / 1000, 3)
            ELSE NULL
        END AS product_weight_kg

    FROM
        `olist-ecommerce-analytics-1.olist_staging.stg_products`
),

product_metrics AS (


    -- 2. PRODUCT TRANSACTION METRICS
    -- GRAIN: 1 row per product_id
    -- PURPOSE: Menghitung performa produk dari transaksi

    SELECT
        product_id,

        COUNT(*) AS total_units_sold,
        COUNT(DISTINCT order_id) AS total_orders,

        ROUND(SUM(price), 2) AS total_revenue,
        ROUND(AVG(price), 2) AS avg_selling_price,

        ROUND(AVG(review_score), 1) AS avg_review_score,

        ROUND(
            AVG(purchase_to_delivery_days),
            1
        ) AS avg_delivery_days

    FROM
        `olist-ecommerce-analytics-1.olist_staging.stg_order_items`

    WHERE is_revenue_generating = TRUE

    GROUP BY product_id
),

product_enriched AS (


    -- 3. ENRICH PRODUCT
    -- Menggabungkan atribut produk dengan metric transaksi

    SELECT
        p.*,

        COALESCE(pm.total_units_sold, 0)
            AS total_units_sold,

        COALESCE(pm.total_orders, 0)
            AS total_orders,

        COALESCE(pm.total_revenue, 0)
            AS total_revenue,

        pm.avg_selling_price,
        pm.avg_review_score,
        pm.avg_delivery_days

    FROM product_base p

    LEFT JOIN product_metrics pm
        ON p.product_id = pm.product_id
)

SELECT
    pe.*,

    cat.product_category_name_english,
    cat.product_super_category,

    -- Listing quality score: 0-100
    ROUND(
        (
            CASE
                WHEN pe.has_photos = TRUE THEN 30
                ELSE 0
            END
            +
            CASE
                WHEN pe.product_photos_qty >= 3 THEN 20
                ELSE 0
            END
            +
            CASE
                WHEN pe.product_description_length > 100 THEN 25
                ELSE 0
            END
            +
            CASE
                WHEN pe.has_complete_dimensions = TRUE THEN 25
                ELSE 0
            END
        ),
        0
    ) AS listing_quality_score

FROM product_enriched pe

LEFT JOIN
    `olist-ecommerce-analytics-1.olist_staging.stg_product_category_translation` cat
    ON pe.product_category_name = cat.product_category_name;