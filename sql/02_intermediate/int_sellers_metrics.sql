create or replace table `olist-ecommerce-analytics-1.olist_intermediate.int_sellers_metrics` as

with base_items as (
    select
        seller_id,
        order_id,
        order_item_id,
        customer_unique_id,
        purchase_date,
        price,
        freight_value,
        item_gmv,
        order_delivered_customer_date,
        purchase_to_approved_hours,
        is_ontime_delivery,
        is_order_date_anomaly
    from `olist-ecommerce-analytics-1.olist_intermediate.int_order_details`
    where is_revenue_generating = true
),

seller_orders as (
    select
        seller_id,
        order_id,
        customer_unique_id,
        purchase_date,
        order_delivered_carrier_date,
        purchase_to_approved_hours,
        is_ontime_delivery,
        is_order_date_anomaly,
        qualify(
            row_number() over(
                partition by seller_id, order_id
                order by order_item_id 
            ) = 1
        )
    from base_items
),

seller_order_metrics as (
    select
        seller_id,
        count(*) as total_orders,
        
)


