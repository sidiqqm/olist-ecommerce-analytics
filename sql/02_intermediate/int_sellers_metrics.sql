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
        purchase_to_delivery_days,
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
        purchase_to_delivery_days,
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
        count(distinct customer_unique_id) as unique_customers,

        round(
            avg(
                case
                    when order_delivered_customer_date is not null
                        and is_order_date_anomaly is not not true
                        then purchase_to_delivery_days
                end
            ), 1
        ) as avg_purchase_to_delivery_days,

        round(
            safe_divide(
                countif(is_ontime_delivery is true) * 100.0,
                countif(is_ontime_delivery is not null)
            ), 2
        ) as seller_otdr_pct,

    from seller_orders
    group by seller_id
),

seller_item_metrics as (
    select
        seller_id,
        count(*) as total_items_sold,
        count(distinct product_id) as unique_products,

        round(sum(price), 2) as total_revenue,
        round(sum(item_gmv), 2) as total_gmv,
        round(avg(price), 2) as avg_item_price,

        min(purchase_date) as first_order_date,
        max(purchase_date) as last_order_date,

    from base_items
    group by seller_id
),

seller_metrics as (
    select 
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
        so.seller_otdr_pct,

    from seller_order_metrics so
    inner join seller_item_metrics si on so.seller_id = si.seller_id
),

seller_ranked as (
    select
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

        percent_rank() over(
            order by total_revenue desc
        ) as revenue_percentile,

        rank() over(
            order by total_orders desc
        ) as order_rank,
        
    from seller_metrics
)

select
    s.seller_id,

    coalesce(sr.total_orders, 0)
        as total_orders,

    coalesce(sr.total_items_sold, 0)
        as total_items_sold,

    coalesce(sr.unique_products, 0)
        as unique_products,

    coalesce(sr.unique_customers, 0)
        as unique_customers,

    coalesce(sr.total_revenue, 0)
        as total_revenue,

    coalesce(sr.total_gmv, 0)
        as total_gmv,

    sr.avg_item_price,
    sr.avg_delivery_days,
    sr.seller_otdr_pct,

    sr.first_sale_date,
    sr.last_sale_date,

    case
        when sr.seller_id is null
            then 'Inactive'
        when sr.revenue_percentile >= 0.8
            then 'Platinum'
        when sr.revenue_percentile >= 0.6
            then 'Gold'
        when sr.revenue_percentile >= 0.4
            then 'Silver'
        else 'Bronze'
    end as seller_tier,

    sr.seller_id is not null
        as is_active_seller

from
    `olist-ecommerce-analytics-1.olist_staging.stg_sellers` as s
left join seller_ranked as sr
    on s.seller_id = sr.seller_id;