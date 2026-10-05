create or replace view `olist-ecommerce-analytics-1.olist_staging.stg_geolocation` as

select
     LPAD(
        cast(geolocation_zip_code_prefix as STRING), 5, "0"
    ) as zip_code_prefix,

    cast(geolocation_lat as FLOAT64) as geolocation_lat,
    cast(geolocation_lng as FLOAT64) as geolocation_lng,
    lower(trim(geolocation_city)) as geolocation_city,
    lower(trim(geolocation_state)) as geolocation_state
from `olist-ecommerce-analytics-1.olist_raw.raw_geolocation`