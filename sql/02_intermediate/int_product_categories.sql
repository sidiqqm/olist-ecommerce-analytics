create or replace view `olist-ecommerce-analytics-1.olist_intermediate.int_product_categories` as

select
    product_category_name,
    product_category_name_english,

    case
        when product_category_name = 'unknown'
            then 'Unknown'

        when product_category_name_english in (
            'bed_bath_table',
            'furniture_decoration',
            'home_confort',
            'home_appliances',
            'home_appliances_2',
            'kitchen_dining_laundry_garden_furniture',
            'housewares',
            'furniture_living_room',
            'furniture_bedroom',
            'furniture_mattress_and_upholstery',
            'home_comfort_2',
            'garden_tools'
        )
            then 'Home & Furniture'

        when product_category_name_english in (
            'computers_accessories',
            'tablets_printing_image',
            'telephony',
            'electronics',
            'computers',
            'consoles_games',
            'fixed_telephony',
            'small_appliances',
            'small_appliances_home_oven_and_coffee',
            'audio',
            'watches_gifts',
            'air_conditioning'
        )
            then 'Electronics & Tech'

        when product_category_name_english in (
            'health_beauty',
            'perfumery',
            'diapers_and_hygiene'
        )
            then 'Health & Beauty'

        when product_category_name_english in (
            'sports_leisure',
            'fashion_bags_accessories',
            'fashion_male_clothing',
            'fashion_female_clothing',
            'fashion_shoes',
            'fashion_underwear_beach',
            'fashion_childrens_clothes',
            'fashion_sport',
            'luggage_accessories'
        )
            then 'Fashion & Sports'

        when product_category_name_english in (
            'auto',
            'auto_parts_accessories'
        )
            then 'Automotive'

        when product_category_name_english in (
            'books_general_interest',
            'books_technical',
            'books_imported',
            'cds_dvds_musicals',
            'dvds_blu_ray',
            'music',
            'arts_and_craftsmanship',
            'stationery'
        )
            then 'Books & Media'

        when product_category_name_english in (
            'food',
            'food_drink',
            'drinks',
            'la_cuisine'
        )
            then 'Food & Beverage'

        when product_category_name_english in (
            'toys',
            'baby',
            'party_supplies'
        )
            then 'Toys & Baby'

        when product_category_name_english in (
            'construction_tools_safety',
            'construction_tools_lights',
            'construction_tools_garden',
            'construction_tools_tools',
            'industry_commerce_and_business',
            'agro_industry_and_commerce',
            'market_place',
            'signaling_and_security',
            'security_and_services'
        )
            then 'Industry & Construction'

        when product_category_name_english = 'pet_shop'
            then 'Pet Shop'

        else 'Other'

    end as product_super_category

from `olist-ecommerce-analytics-1.olist_staging.stg_product_category_translation`;