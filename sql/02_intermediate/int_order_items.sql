create or replace view `olist-ecommerce-analytics-1.olist_intermediate.int_order_items` as 

with metrics as (
    select 
        order_id,
        product_id,
        order_item_id,
        price,
        freight_value,

        price + freight_value as item_gmv,

        case when price <= 0 then true else false end as is_zero_or_negative_price,

        case when freight_value = 0 then true else false end as is_free_shipping,

        case
            when price > 0
                then round(
                    safe_divide(freight_value, price) * 100,
                    2
                )
            else null
        end as freight_to_price_pct,
        
    from `olist-ecommerce-analytics-1.olist_staging.stg_order_items`
)

select * from metrics;