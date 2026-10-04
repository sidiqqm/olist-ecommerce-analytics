create or replace view `olist-ecommerce-analytics-1.olist_staging.stg_geolocation` as

select
     LPAD(
        cast(geolocation_zip_code_prefix as STRING), 5, "0"
    ) as zip_code_prefix,

    cast(gelocation_lat as FLOAT64) as gelocation_lat,
    cast(gelocation_ing as FLOAT64) as gelocation_ing,
    lower(trim(geolocation_city)),
    lower(trim(geolocation_state))
from `olist-ecommerce-analytics-1.olist_raw.raw_geolocation`