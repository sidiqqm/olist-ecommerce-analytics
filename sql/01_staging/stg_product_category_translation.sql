CREATE OR REPLACE VIEW `olist-ecommerce-analytics-1.olist_staging.stg_product_category_translation` AS

WITH

base AS (
    SELECT
        LOWER(TRIM(string_field_0))                  AS product_category_name,
        TRIM(string_field_1)                 AS product_category_name_english
    FROM `olist-ecommerce-analytics-1.olist_raw.raw_product_category_translation`
),

-- Tambahkan baris 'unknown' untuk handle produk tanpa kategori
-- Alasan: Di stg_products, NULL category sudah di-COALESCE ke 'unknown'
-- Agar join ke tabel ini tidak menghasilkan NULL pada category English,
-- kita tambahkan mapping 'unknown' → 'Unknown Category'
with_unknown AS (
    SELECT * FROM base

    UNION ALL

    SELECT
        'unknown'                           AS product_category_name,
        'Unknown Category'                  AS product_category_name_english
)

SELECT
    product_category_name,
    product_category_name_english,

    -- DERIVED: High-level category grouping
    -- Bisnis: 73 kategori terlalu banyak untuk beberapa visualisasi.
    -- Kita buat super-category untuk executive dashboard.
    CASE
        WHEN product_category_name_english IN (
            'bed_bath_table', 'furniture_decoration', 'home_confort',
            'home_appliances', 'home_appliances_2', 'kitchen_dining_laundry_garden_furniture',
            'housewares', 'furniture_living_room', 'furniture_bedroom',
            'furniture_mattress_and_upholstery', 'home_comfort_2', 'garden_tools'
        ) THEN 'Home & Furniture'

        WHEN product_category_name_english IN (
            'computers_accessories', 'tablets_printing_image',
            'telephony', 'electronics', 'computers', 'consoles_games',
            'fixed_telephony', 'small_appliances', 'small_appliances_home_oven_and_coffee',
            'audio', 'watches_gifts', 'air_conditioning'
        ) THEN 'Electronics & Tech'

        WHEN product_category_name_english IN (
            'health_beauty', 'perfumery', 'diapers_and_hygiene'
        ) THEN 'Health & Beauty'

        WHEN product_category_name_english IN (
            'sports_leisure', 'fashion_bags_accessories',
            'fashion_male_clothing', 'fashion_female_clothing',
            'fashion_shoes', 'fashion_underwear_beach',
            'fashion_childrens_clothes', 'fashion_sport',
            'luggage_accessories'
        ) THEN 'Fashion & Sports'

        WHEN product_category_name_english IN (
            'auto', 'auto_parts_accessories'
        ) THEN 'Automotive'

        WHEN product_category_name_english IN (
            'books_general_interest', 'books_technical', 'books_imported',
            'cds_dvds_musicals', 'dvds_blu_ray', 'music',
            'arts_and_craftsmanship', 'stationery'
        ) THEN 'Books & Media'

        WHEN product_category_name_english IN (
            'food', 'food_drink', 'drinks', 'la_cuisine'
        ) THEN 'Food & Beverage'

        WHEN product_category_name_english IN (
            'toys', 'baby', 'party_supplies'
        ) THEN 'Toys & Baby'

        WHEN product_category_name_english IN (
            'construction_tools_safety', 'construction_tools_lights',
            'construction_tools_garden', 'construction_tools_tools',
            'industry_commerce_and_business', 'agro_industry_and_commerce',
            'market_place', 'signaling_and_security', 'security_and_services'
        ) THEN 'Industry & Construction'

        WHEN product_category_name_english IN (
            'pet_shop'
        ) THEN 'Pet Shop'

        WHEN product_category_name_english = 'Unknown Category'
        THEN 'Unknown'

        ELSE 'Other'
    END                                                     AS product_super_category

FROM with_unknown;