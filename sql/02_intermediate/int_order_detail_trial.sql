create or replace table
    `olist-ecommerce-analytics-1.olist_intermediate.int_order_detail`

partition by purchase_date
cluster by order_status, customer_id

as

with payments_aggregated as (
    select
        order_id,
        sum(payment_value) as total_payment_value,

        max(
            case
                when is_primary_payment
                then payment_type
            end
        ) as primary_payment_type,

        max(
            case
                when is_primary_payment
                then payment_installments
            end
        ) as primary_payment_installments,

        logical_or(payment_type = 'voucher') as used_voucher,

        count(*) as payment_record_count,

        count(distinct payment_type) as payment_method_count,

        count(distinct payment_type) > 1 as is_split_payment

    from `olist-ecommerce-analytics-1.olist_intermediate.int_order_payments`

    group by order_id
),

reviews_ranked as (
    select
        review_id,
        order_id,
        review_score,
        review_sentiment,
        review_score_label,
        has_comment,
        has_responded,
        hours_to_respond,
        review_answer_date,

        row_number() over (
            partition by order_id
            order by
                review_answer_date desc nulls last,
                review_id desc
        ) as rn

    from `olist-ecommerce-analytics-1.olist_intermediate.int_order_reviews`
),

reviews_deduped as (
    select
        order_id,
        review_score,
        review_sentiment,
        review_score_label,
        has_comment,
        has_responded,
        hours_to_respond,
        review_answer_date

    from reviews_ranked

    where rn = 1
)

select
    o.order_id,
    o.customer_id,

    c.customer_unique_id,
    c.customer_zip_code_prefix, 
    c.customer_city,
    c.customer_state,
    c.customer_region,

    o.order_status,

    o.is_revenue_generating,
    o.is_on_time_delivery,
    o.is_delivery_date_anomaly,

    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,

    o.purchase_date,

    o.purchase_to_approval_days,
    o.purchase_to_delivery_days,
    o.delivery_vs_estimate_days,

    -- payment: grain order
    pay.total_payment_value,
    pay.primary_payment_type,
    pay.primary_payment_installments,
    pay.used_voucher,
    pay.payment_record_count,
    pay.payment_method_count,
    pay.is_split_payment,

    -- review: grain order
    rev.review_score,
    rev.review_sentiment,
    rev.review_score_label,
    rev.has_comment as review_has_comment,
    rev.has_responded as review_has_responded,
    rev.hours_to_respond as review_hours_to_respond,
    rev.review_answer_date

from `olist-ecommerce-analytics-1.olist_intermediate.int_orders` o

left join `olist-ecommerce-analytics-1.olist_staging.stg_customers` c
    on o.customer_id = c.customer_id

left join payments_aggregated pay
    on o.order_id = pay.order_id

left join reviews_deduped rev
    on o.order_id = rev.order_id;