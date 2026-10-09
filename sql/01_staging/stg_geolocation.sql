create or replace view
    `olist-ecommerce-analytics-1.olist_staging.stg_geolocation` as

with normalized as (

    select
        lpad(
            trim(cast(geolocation_zip_code_prefix as string)),
            5,
            '0'
        ) as zip_code_prefix,

        safe_cast(geolocation_lat as float64) as latitude,
        safe_cast(geolocation_lng as float64) as longitude,

        nullif(
            lower(trim(geolocation_city)),
            ''
        ) as city,

        nullif(
            upper(trim(geolocation_state)),
            ''
        ) as state

    from `olist-ecommerce-analytics-1.olist_raw.raw_geolocation`

),

valid_coordinates as (

    select *
    from normalized

    where latitude between -33.75 and 5.27
      and longitude between -73.99 and -28.85

),

aggregated_coordinates as (

    select
        zip_code_prefix,

        round(avg(latitude), 6) as geolocation_lat,
        round(avg(longitude), 6) as geolocation_lng,

        count(*) as source_point_count

    from valid_coordinates

    group by zip_code_prefix

),

location_frequency as (

    select
        zip_code_prefix,
        city,
        state,
        count(*) as location_count

    from valid_coordinates

    where city is not null
       or state is not null

    group by
        zip_code_prefix,
        city,
        state

),

location_mode as (

    select
        zip_code_prefix,
        city,
        state

    from location_frequency

    qualify row_number() over (
        partition by zip_code_prefix
        order by
            location_count desc,
            city,
            state
    ) = 1

),

enriched as (

    select
        a.zip_code_prefix,
        a.geolocation_lat,
        a.geolocation_lng,

        m.city as geolocation_city,
        m.state as geolocation_state,

        a.source_point_count

    from aggregated_coordinates as a

    left join location_mode as m
        using (zip_code_prefix)

)

select
    *,

    case
        when geolocation_state in ('SP', 'RJ', 'MG', 'ES')
            then 'Southeast'

        when geolocation_state in ('RS', 'SC', 'PR')
            then 'South'

        when geolocation_state in ('MT', 'MS', 'GO', 'DF')
            then 'Center-West'

        when geolocation_state in (
            'BA', 'CE', 'PE', 'MA', 'PB',
            'RN', 'PI', 'AL', 'SE'
        )
            then 'Northeast'

        when geolocation_state in (
            'AM', 'PA', 'RO', 'AC',
            'AP', 'RR', 'TO'
        )
            then 'North'

        else 'Unknown'
    end as geolocation_region

from enriched;