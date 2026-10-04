-- order_id	payment_sequential	payment_type	payment_installments	payment_value

create or replace view `olist-ecommerce-analytics-1.olist_staging.stg_order_payments` as

select
    order_id,
    cast(payment_sequential as INT64) as payment_sequential,
    lower(trim(payment_type)) as payment_type,
    cast(payment_installments as INT64) as payment_installments,
    cast(payment_value as NUMERIC) as payment_value
from `olist-ecommerce-analytics-1.olist_raw.raw_order_payments`