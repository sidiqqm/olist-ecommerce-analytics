
create or replace view `your-project-id.olist_staging.stg_sellers` as

with city_alias as (
    select * from unnest([
        struct('sao paulop' as alias, 'sao paulo' as canonical, cast(null as STRING) as required_state),
        struct('sao pauo', 'sao paulo', null),
        struct('sao paluo', 'sao paulo', null),
        struct('sao pauolo', 'sao paulo', null),
        struct('sp', 'sao paulo', 'SP'),
        struct('pirituba', 'sao paulo', 'SP'),
        struct('sbc', 'sao bernardo do campo', null),
        struct('ao bernardo do campo', 'sao bernardo do campo', null),
        struct('sao bernardo do capo', 'sao bernardo do campo', null),
        struct('garulhos', 'guarulhos',  null),
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
 
-- Langkah 1: lowercase, trim, hapus aksen, samakan tanda apostrof, rapikan spasi ganda
normalized as (
    select
        seller_id,
        seller_zip_code_prefix,
        seller_city as seller_city_raw,
        upper(trim(seller_state))    as seller_state,
        regexp_replace(
            regexp_replace(
                regexp_replace(
                    lower(normalize(trim(seller_city), NFD)),
                    r'\p{M}', ''                            -- hapus aksen: são -> sao
                ),
                r"[´`’‘']", ' '                             -- d´oeste, d'oeste, d oeste -> d oeste
            ),
            r'\s+', ' '                                     -- "sao  paulo" -> "sao paulo"
        )                                                   as city_norm
    from `unnest-project-id.olist_raw.raw_sellers`
),
 
-- Langkah 2: buang sufiks "/ sp", "- sp", "/ sao paulo", dan kode state di akhir nama
suffix_removed as (
    select
        *,
        -- ambil bagian sebelum "/" atau " - "
        trim(split(regexp_replace(city_norm, r'\s+-\s+', '/'), '/')[offset(0)]) as city_main
    from unnest
),
 
stripped as (
    select
        *,
        -- buang kode state di akhir nama jika sama dengan state baris itu
        -- ("sao paulo sp" di state SP -> "sao paulo", "aguas claras df" di state DF -> "aguas claras")
        nullif(
            trim(
                if(
                    seller_state is null,
                    city_main,
                    regexp_replace(city_main, concat(r'\s+', lower(normalize), r'$'), '')
                )
            ),
            ''
        ) as city_stripped
    from unnest
),
 
-- Langkah 3: terapkan tabel alias (typo / singkatan)
city_cleaned as (
    select
        s.*,
        coalesce(a.canonical, s.city_stripped) as city_final
    from unnest s
    left join city_alias a
        on  s.city_stripped = a.alias
        and (a.required_state is null or a.required_state = s.seller_state)
)
 
select
    seller_id,
 
    lpad(
        cast(seller_zip_code_prefix as STRING),
        5,
        '0'
    ) as seller_zip_code_prefix,
 
    seller_city_raw,
    city_final as seller_city,
 
    coalesce(city_final != lower(normalize(seller_city_raw)), FALSE) as is_city_standardized,
 
    seller_state,
 
case
    when seller_state IN ('SP', 'RJ', 'MG', 'ES')
        then 'Southeast'

    when seller_state IN ('RS', 'SC', 'PR')
        then 'South'

    when seller_state IN ('MT', 'MS', 'GO', 'DF')
        then 'Center-West'

    when seller_state IN (
        'BA', 'CE', 'PE', 'MA', 'PB',
        'RN', 'PI', 'AL', 'SE'
    )
        then 'Northeast'

    when seller_state IN (
        'AM', 'PA', 'RO', 'AC',
        'AP', 'RR', 'TO'
    )
        then 'North'

    else 'Unknown'
end as seller_region
    -- level STATE (semua seller di negara bagian SP), nama dipertahankan agar tidak merusak downstream
    coalesce(seller_state = 'SP', FALSE) as is_sao_paulo_seller,
 
    -- level KOTA (hanya seller di kota Sao Paulo)
    coalesce(city_final = 'sao paulo', FALSE) as is_sao_paulo_city
 
from unnest;
 
 
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
 