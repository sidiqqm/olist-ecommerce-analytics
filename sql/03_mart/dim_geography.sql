create or replace table `olist-ecommerce-analytics-1.olist_mart.dim_geography` as 

select
    zip_code_prefix,
    geolocation_city as city,
    geolocation_state as state_code,
    geolocation_region as region,
    
    case geolocation_state
        when 'SP' then 'São Paulo'
        when 'RJ' then 'Rio de Janeiro'
        when 'MG' then 'Minas Gerais'
        when 'RS' then 'Rio Grande do Sul'
        when 'PR' then 'Paraná'
        when 'SC' then 'Santa Catarina'
        when 'BA' then 'Bahia'
        when 'GO' then 'Goiás'
        when 'DF' then 'Distrito Federal'
        when 'ES' then 'Espírito Santo'
        when 'PE' then 'Pernambuco'
        when 'CE' then 'Ceará'
        when 'PA' then 'Pará'
        when 'MT' then 'Mato Grosso'
        when 'MS' then 'Mato Grosso do Sul'
        when 'RO' then 'Rondônia'
        when 'AM' then 'Amazonas'
        when 'AL' then 'Alagoas'
        when 'MA' then 'Maranhão'
        when 'PB' then 'Paraíba'
        when 'PI' then 'Piauí'
        when 'RN' then 'Rio Grande do Norte'
        when 'SE' then 'Sergipe'
        when 'TO' then 'Tocantins'
        when 'AC' then 'Acre'
        when 'AP' then 'Amapá'
        when 'RR' then 'Roraima'
        else 'Unknown'
    end as state_name,

    geolocation_lat as latitude,
    geolocation_lng as longitude,
    source_point_count

from `olist-ecommerce-analytics-1.olist_staging.stg_geolocation`