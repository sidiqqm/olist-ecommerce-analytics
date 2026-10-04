-- 1.1 Verifikasi dataset

select
    'raw_orders' as table_name,
    count(*) as row_count,
    9941 as expected_count,
    count(distinct order_id) as unique_orders,
    min(order_purchase_time) as earliest_order,
    max(order_purchase_time) as latest_order
from `olist-ecommerce-analytics-1.olist_raw.raw_orders`

select
    'raw_orders_item' as table_name,
    count(*) as row_count,
    112650 as expected_count,
    count(distinct order_item_id) as unique_order_item,
    count(distinct seller_id) as unique_seller,
    count(distinct product_id) as unique_product,
    round(sum(price), 2) as total_price_brl,
    round(sum(freight_value), 2) as total_freight_brl
    round(sum(price + freight_value), 2) as total_gmv_brl
from `olist-ecommerce-analytics-1.olist_raw.raw_order_items`

select
    'raw_order_payments' as table_name,
    count(*) as row_count,
    103886 as expected_count,
    count(distinct order_id) as unique_orders_with_payment,
    count(distinct payment_type) as unique_payment_type,
    round(sum(payment_value), 2) as total_payment_value_brl,
    string_agg(payment_type) as payment_types_found
from `olist-ecommerce-analytics-1.olist_raw.raw_order_payments`

select
    'raw_order_reviews' as table_name,
    count(*) as row_count,
    99224 as expected_count,
    count(distinct order_id) as unique_orders_with_review,
    count(distinct review_id) as unique_reviews,
    round(avg(review_score), 4) as avg_review_score,
    min(review_score) as min_review_score,
    max(review_score) as max_review_score
from `olist-ecommerce-analytics-1.olist_raw.raw_order_reviews`

select
    'raw_customers' as table_name,
    count(*) as row_count,
    99441 as expected_count,
    count(distinct customer_id) as unique_customers_ids,
    count(distinct customer_unique_id) as unique_individual_customers,
    count(distinct customer_state) as states_covered,
from `olist-ecommerce-analytics-1.olist_raw.raw_customers`

select
    'raw_sellers' as table_name,
    count(*) as row_count,
    3095 as expected_count,
    count(distinct seller_id) as unique_sellers,
    count(distinct seller_state) as seller_states
from `olist-ecommerce-analytics-1.olist_raw.raw_sellers`

select
    'raw_products' as table_name.
    count(*) as row_count,
    32951 as expected_count,
    count(distinct product_id) as unique_products,
    count(distinct product_category_name) as unique_categories,
    countif(product_category_name is null) as null_categories,
    countif(product_weight_g is null) as null_weights
from `olist-ecommerce-analytics-1.olist_raw.raw_products`

select
    'raw_geolocation' as table_name,
    count(*) as row_count,
    count(distinct geolocation_zip_code_prefix) as unique_zip_prefixes,
    count(distinct geolocation_state) as states_covered,
    -- Verifikasi koordinat dalam range Brazil
    -- Bounding box Brazil: lat (-33.75 to 5.27), lng (-73.99 to -28.85)
    countif(
        geolocation_lat between -33.75 and 5.27
        and geolocation_lng between -73.99 and -28.85
    ) as valid_brazil_coordinates,
    countif(
        geolocation_lat NOT between -33.75 and 5.27
        OR geolocation_lng NOT between -73.99 and -28.85
    ) as invalid_coordinates
from `olist-ecommerce-analytics-1.olist_raw.raw_geolocation`;

select
    'raw_product_category_translation' as table_name,
    count(*) as row_count,
    71 as expected_count,
    count(DISTINCT product_category_name) as unique_categories_pt,
    count(DISTINCT product_category_name_english) as unique_categories_en
from `olist-ecommerce-analytics-1.olist_raw.raw_product_category_translation`;

