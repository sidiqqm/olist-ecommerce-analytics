sql
CREATE OR REPLACE VIEW
  `olist-ecommerce-analytics-1.olist_intermediate.int_products`
AS
WITH product_base AS (

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

        CASE
            WHEN product_weight_g IS NOT NULL
            THEN ROUND(product_weight_g / 1000, 3)
            ELSE NULL
        END AS product_weight_kg

    FROM
        `olist-ecommerce-analytics-1.olist_staging.stg_products`
),