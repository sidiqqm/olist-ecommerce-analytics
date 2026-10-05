create or replace view `olist-ecommerce-analytics-1.olist_intermediate.int_orders` as

with flag as (
    select
        order_id,
        customer_id,
        order_status,
        order_purchase_timestamp,
        order_approved_at,
        order_delivered_carrier_date,
        order_delivered_customer_date,
        order_estimated_delivery_date,

        order_delivered_carrier_date is not null as is_shipped,
        order_delivered_customer_date is not null as is_delivered,
        order_approved_at is not null as is_approved,

        case
            when lower(trim(order_status)) = 'delivered' then true
            else false
        end as is_revenue_generating,

        case
            when (
                (order_approved_at is not null
                and order_purchase_timestamp is not null
                and order_approved_at < order_purchase_timestamp)

                or

                (order_delivered_carrier_date is not null
                and order_approved_at is not null
                and order_delivered_carrier_date < order_approved_at)

                or

                (order_delivered_customer_date is not null
                and order_delivered_carrier_date is not null
                and order_delivered_customer_date < order_delivered_carrier_date)

                or

                (order_delivered_customer_date is not null
                and order_purchase_timestamp is not null
                and order_delivered_customer_date < order_purchase_timestamp)

                or

                (order_estimated_delivery_date is not null
                and order_purchase_timestamp is not null
                and order_estimated_delivery_date < date(order_purchase_timestamp))
            )
            then true
            else false
        end as is_order_date_anomaly,

        case
            when order_delivered_customer_date is not null
                and order_estimated_delivery_date is not null
                and order_delivered_customer_date <= order_estimated_delivery_date
            then true

            when order_delivered_customer_date is not null
                and order_estimated_delivery_date is not null
                and order_delivered_customer_date > order_estimated_delivery_date
            then false

            else null
        end as is_ontime_delivery,

        case
            when order_delivered_customer_date is not null
                and order_purchase_timestamp is not null
            then date_diff(
                date(order_delivered_customer_date),
                date(order_purchase_timestamp),
                day
            )
            else null
        end as purchase_to_delivery_days,

        case
            when order_delivered_customer_date is not null
                and order_estimated_delivery_date is not null
            then timestamp_diff(
                date(order_delivered_customer_date),
                date(order_estimated_delivery_date),
                day
            )
            else null
        end as delivery_vs_estimated_days,

        case
            when order_purchase_timestamp is not null
                and order_approved_at is not null
            then timestamp_diff(
                order_approved_at,
                order_purchase_timestamp,
                hour
            )
            else null
        end as purchase_to_approved_hours,

        case
            when lower(trim(order_status)) = 'delivered' and order_delivered_customer_date > order_estimated_delivery_date then 'late'
            when lower(trim(order_status)) = 'delivered' and order_delivered_customer_date <= order_estimated_delivery_date then 'on_time'
            when lower(trim(order_status)) = 'shipped' and order_delivered_customer_date is null then 'in_transit'
            when lower(trim(order_status)) = 'canceled' or order_status = 'unavailable' then 'cancelled'
            when lower(trim(order_status)) = 'processing' then 'processing'
            else 'unknown'
        end as delivery_status,

        date(order_purchase_timestamp) as purchase_date,
        extract(year from order_purchase_timestamp) as purchase_year,
        extract(month from order_purchase_timestamp) as purchase_month,
        extract(day from order_purchase_timestamp) as purchase_day,
        extract(dayofweek from order_purchase_timestamp) as purchase_day_of_week,
        format_timestamp('%Y-%m', order_purchase_timestamp) as purchase_year_month,
        format_timestamp('%Y-Q%Q', order_purchase_timestamp) as purchase_year_quarter,

        extract(year from order_purchase_timestamp) * 12 + 
            (extract(month from order_purchase_timestamp) - 1) AS purchase_ym_int
    from `olist-ecommerce-analytics-1.olist_staging.stg_orders`
)

select *
from flag;