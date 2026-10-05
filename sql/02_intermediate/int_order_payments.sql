create or replace view `olist-ecommerce-analytics-1.olist_intermediate.int_order_payments` as 

with flag as (
    select 
        order_id,
        payment_sequential,
        payment_type,
        payment_installments,
        
        payment_sequential = 1 as is_primary_payment,
        case
            when payment_type = 'not_defined'
            then true
            else false
        end as is_undefined_payment,
        
        case
            when payment_installments > 1 then true
            else false
        end as is_installment,
        
        case
            when payment_installments = 1 then '1 - Full Payment'
            when payment_installments <= 3 then '2-3 - Short Term'
            when payment_installments <= 6 then '4-6 - Medium Term'
            when payment_installments <= 12 then '7-12 - Long Term'
            else '12+ - Extended'
        end as installment_category

    from `olist-ecommerce-analytics-1.olist_staging.stg_order_payments`
)

select * from flag 