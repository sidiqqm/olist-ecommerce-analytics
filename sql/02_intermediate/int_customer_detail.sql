create or replace table `olist-ecommerce-analytics-1.olist_intermediate.int_customer_metrics`

with customer_orders as (
    select
        c.customer_unique_id,
        o.order_id,
        o.purchase_date,
        o.purchase_year_month,
        o.is_revenue_generating,
        o.is_delivered,
        o.is_ontime_delivery

        sum(coalesce(oi.item_gmv, 0)) as order_gmv,
        sum(coalesce(oi.price, 0)) as order_price_total,
        countif(oi.order_item_id) as item_count_per_order

    from `olist-ecommerce-analytics-1.olist_int.int_orders` o

    join `olist-ecommerce-analytics-1.olist_staging.stg_customers` c
        on o.customer_id = c.customer_unique_id
    
    left join `olist-ecommerce-analytics-1.olist_intermediate.int_order_items` oi
        on o.order_id = oi.order_id

    group by 
        c.customer_unique_id,
        o.order_id,
        o.purchase_date,
        o.purchase_year_month,
        o.is_revenue_generating,
        o.is_delivered,
        o.is_ontime_delivery

), 

customer_summary as (
    select
        customer_unique_id,

        -- frequency
        count(distinct order_id) as total_orders,
        countif(is_revenue_generating) as revenue_generating_orders,
        countif(is_delivered) as delivered_orders,
        
        -- recency
        min(purchase_date) as first_purchase_date,
        max(purchase_date) as last_purchase_date,
        
        date_diff(
            (select max(purchase_date) from customer_orders),
            max(purchase_date),
            date
        ) as recency_days,

        -- monetary
        sum(
            case when is_revenue_generating
                then order_gmv
                else 0
            end
        ) as total_clv,

        avg(
            case when is_revenue_generating
                then order_gmv
                else 0
            end
        ) as avg_order_value,

        max(
            case when is_revenue_generating
                then order_gmv
                else 0
            end
        ) as max_order_value,

        countif(is_revenue_generating) > 1
            as is_repeat_customer,

        count(
            distinct case
                when is_revenue_generating
                    then purchase_year_month
            end
        ) as active_months,

    from customer_orders
    group by customer_unique_id
),

fm_scored as (

    select
        *,

        ntile(5) over (
            order by recency_days desc
        ) as r_score,

        ntile(5) over (
            order by revenue_generating_orders asc
        ) as f_score,

        ntile(5) over (
            order by total_clv asc
        ) as m_score

    from customer_summary
),

rfm_segmented as (

    select
        *,

        concat(
            cast(r_score as string),
            cast(f_score as string),
            cast(m_score as string)
        ) as rfm_score,

        round(
            (r_score + f_score + m_score) / 3.0,
            2
        ) as rfm_avg_score,

        case

            when r_score = 5
                and f_score >= 4
                and m_score >= 4
                then 'Champions'

            when f_score >= 4
                and m_score >= 4
                then 'Loyal Customers'

            when r_score <= 2
                and f_score >= 4
                and m_score >= 4
                then 'At Risk'

            when r_score >= 4
                and f_score >= 2
                and m_score >= 2
                then 'Potential Loyalists'

            when r_score >= 4
                and f_score <= 2
                then 'Recent Customers'

            when r_score = 3
                and f_score >= 3
                and m_score >= 3
                then 'Need Attention'

            when r_score = 3
                and f_score <= 2
                then 'Promising'

            when r_score <= 2
                and f_score >= 2
                and m_score >= 2
                then 'About to Sleep'

            when r_score <= 2
                and f_score <= 2
                then 'Hibernating'

            else 'Others'

        end as rfm_segment

    from rfm_scored
)

select *
from rfm_segmented;