-- customer_id	customer_unique_id	customer_zip_code_prefix	customer_city	customer_state

create or replace view `olist-ecommerce-analytics-1.olist_staging.stg_customers` as

select
    customer_id,
    customer_unique_id,
    LPAD(
        cast(customer_zip_code_prefix as STRING), 5, "0"
    ) as customer_zip_code_prefix,
    lower(trim(customer_city)) as customer_city,
    lower(trim(customer_state)) as customer_state,
    case
        when upper(trim(customer_state)) IN ('SP', 'RJ', 'MG', 'ES')
            THEN 'Southeast'

        when upper(trim(customer_state)) IN ('RS', 'SC', 'PR')
            THEN 'South'

        when upper(trim(customer_state)) IN ('MT', 'MS', 'GO', 'DF')
            THEN 'Center-West'

        when upper(trim(customer_state)) IN (
            'BA', 'CE', 'PE', 'MA', 'PB', 'RN', 'PI', 'AL', 'SE'
        )
            THEN 'Northeast'

        when upper(trim(customer_state)) IN (
            'AM', 'PA', 'RO', 'AC', 'AP', 'RR', 'TO'
        )
            THEN 'North'
    else 'Unknown'
end as customer_region
from `olist-ecommerce-analytics-1.olist_raw.raw_customers`