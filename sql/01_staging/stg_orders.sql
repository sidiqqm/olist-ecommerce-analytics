create or replace view `olist-ecommerce-analytics-1.olist_staging.stg_orders` as

select
    order_id,
    customer_id,
    
    lower(trim(order_status)) as order_status,
    
    cast(order_purchase_time as timestamp) as order_purchase_time,
    cast(order_approved_at as timestamp) as order_approved_at,
    cast(order_delivered_carrier_date as timestamp) as order_delivered_carrier_date,
    cast(order_delivered_customer_date as timestamp) as order_delivered_customer_date,
    cast(order_estimated_delivery_date as timestamp) as order_estimated_delivery_date
from `olist-ecommerce-analytics-1.olist_raw.raw_orders`;