-- PRODUCT DIMENSION TABLE
-- GRAIN: 1 row per product_id

CREATE OR REPLACE TABLE
  `olist-ecommerce-analytics-1.olist_mart.dim_products`
AS

SELECT
    p.product_id,

    p.product_category_name,
    cat.product_category_name_english,
    cat.product_super_category,
    p.is_unknown_category,

    p.product_name_length,
    p.product_description_length,
    p.product_photos_qty,
    p.has_photos,

    p.has_complete_dimensions,
    p.has_weight,
    p.product_weight_g,
    p.product_weight_kg,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm,
    p.volumetric_weight_kg,

    p.listing_quality_score

FROM
  `olist-ecommerce-analytics-1.olist_intermediate.int_products_metrics` p

LEFT JOIN
  `olist-ecommerce-analytics-1.olist_staging.stg_product_category_translation` cat
    ON p.product_category_name = cat.product_category_name;