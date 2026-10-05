create or replace view `olist-ecommerce-analytics-1.olist_staging.stg_sellers` as

with city_alias as (

    select *
    from unnest([
        struct(
            'sao paulop' as alias,
            'sao paulo' as canonical,
            cast(null as string) as required_state
        ),
        struct('sao pauo', 'sao paulo', null),
        struct('sao paluo', 'sao paulo', null),
        struct('sao pauolo', 'sao paulo', null),
        struct('sp', 'sao paulo', 'SP'),
        struct('pirituba', 'sao paulo', 'SP'),
        struct('sbc', 'sao bernardo do campo', null),
        struct('ao bernardo do campo', 'sao bernardo do campo', null),
        struct('sao bernardo do capo', 'sao bernardo do campo', null),
        struct('garulhos', 'guarulhos', null),
        struct('tabao da serra', 'taboao da serra', null),
        struct('mogi das cruses', 'mogi das cruzes', null),
        struct('sando andre', 'santo andre', null),
        struct('ribeirao pretp', 'ribeirao preto', null),
        struct('robeirao preto', 'ribeirao preto', null),
        struct('riberao preto', 'ribeirao preto', null),
        struct('portoferreira', 'porto ferreira', null),
        struct('scao jose do rio pardo', 'sao jose do rio pardo', null),
        struct('s jose do rio preto', 'sao jose do rio preto', null),
        struct('sao jose do rio pret', 'sao jose do rio preto', null)
    ])

),

normalized as (

    select
        seller_id,

        seller_zip_code_prefix,

        seller_city as seller_city_raw,

        upper(trim(seller_state)) as seller_state,

        regexp_replace(
            regexp_replace(
                regexp_replace(
                    lower(
                        normalize(
                            trim(seller_city),
                            NFD
                        )
                    ),
                    r'\p{M}',
                    ''
                ),
                r"[´`’‘']",
                ' '
            ),
            r'\s+',
            ' '
        ) as city_norm

    from `olist-ecommerce-analytics-1.olist_raw.raw_sellers`

),

suffix_removed as (

    select
        *,

        trim(
            split(
                regexp_replace(
                    city_norm,
                    r'\s+-\s+',
                    '/'
                ),
                '/'
            )[offset(0)]
        ) as city_main

    from normalized

),

stripped as (

    select
        *,

        nullif(
            trim(
                case
                    when seller_state is null then city_main

                    else regexp_replace(
                        city_main,
                        concat(
                            r'\s+',
                            lower(
                                normalize(
                                    seller_state,
                                    NFD
                                )
                            ),
                            r'$'
                        ),
                        ''
                    )
                end
            ),
            ''
        ) as city_stripped

    from suffix_removed

),

city_cleaned as (

    select
        s.*,

        coalesce(
            a.canonical,
            s.city_stripped
        ) as city_final

    from stripped as s

    left join city_alias as a
        on s.city_stripped = a.alias
        and (
            a.required_state is null
            or a.required_state = s.seller_state
        )

)

select
    seller_id,

    lpad(
        cast(seller_zip_code_prefix as string),
        5,
        '0'
    ) as seller_zip_code_prefix,

    seller_city_raw,

    city_final as seller_city,

    coalesce(
        city_final != city_norm,
        false
    ) as is_city_standardized,

    seller_state,

    case
        when seller_state in ('SP', 'RJ', 'MG', 'ES')
            then 'Southeast'

        when seller_state in ('RS', 'SC', 'PR')
            then 'South'

        when seller_state in ('MT', 'MS', 'GO', 'DF')
            then 'Center-West'

        when seller_state in (
            'BA', 'CE', 'PE', 'MA', 'PB',
            'RN', 'PI', 'AL', 'SE'
        )
            then 'Northeast'

        when seller_state in (
            'AM', 'PA', 'RO', 'AC',
            'AP', 'RR', 'TO'
        )
            then 'North'

        else 'Unknown'
    end as seller_region,

    seller_state = 'SP' as is_sao_paulo_seller,

    city_final = 'sao paulo' as is_sao_paulo_city

from city_cleaned

-- =====================================================================
-- Query validasi (jalankan manual setelah view dibuat):
--
-- 1) Cek varian yang berubah dan jumlahnya
-- select seller_city_raw, seller_city, COUNT(*) as n
-- from `unnest-project-id.olist_staging.stg_sellers`
-- WHERE is_city_standardized
-- GROUP BY 1, 2 ORDER BY n DESC;
--
-- 2) Cari kota yang mirip tapi belum ter-mapping (kandidat typo baru)
-- select seller_city, COUNT(*) as n
-- from `unnest-project-id.olist_staging.stg_sellers`
-- GROUP BY 1 HAVING n <= 2 ORDER BY seller_city;
-- =====================================================================
 