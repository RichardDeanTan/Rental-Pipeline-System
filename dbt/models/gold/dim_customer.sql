-- dim_customer : dimensi SCD Type 2. Satu baris = satu VERSI customer.
--
-- Sumber: snapshot scd_customer (yang menyimpan riwayat versi), lalu diratakan
-- dengan address -> city -> country.
--
-- PENTING — dua boolean yang berbeda dan mudah tertukar:
--   is_current : TRUE untuk VERSI TERKINI dari baris SCD2 ini (urusan warehouse).
--   is_active  : status keaktifan customer di sistem sumber (dari activebool).
--   Sebuah customer bisa punya is_current=TRUE tapi is_active=FALSE
--   (versi terkini-nya menyatakan dia sudah tidak aktif).
--
-- customer_sk di-hash dari (customer_id + effective_start_date) sehingga TIAP
-- VERSI punya SK unik. Inilah yang membuat fact bisa menunjuk ke versi yang
-- benar pada saat transaksi terjadi.
--
-- effective_end_date memakai 9999-12-31 (bukan NULL) untuk versi terkini,
-- supaya klausa BETWEEN di fact bekerja tanpa perlu COALESCE.

{{ config(materialized='table') }}

with snap as (
    select * from {{ ref('scd_customer') }}
),

address as (
    select * from {{ ref('stg_address') }}
),

city as (
    select * from {{ ref('stg_city') }}
),

country as (
    select * from {{ ref('stg_country') }}
),

versioned as (
    select
        s.customer_id,
        s.store_id,
        s.first_name,
        s.last_name,
        s.email,
        s.address_id,
        s.is_active,
        s.create_date,
        s.last_update,
        -- BACKDATING VERSI PERTAMA (penting!):
        -- Snapshot pertama dijalankan HARI INI, jadi dbt_valid_from = hari ini.
        -- Padahal data rental/payment berasal dari 2005-2007. Kalau dipakai apa
        -- adanya, join SCD2 di fact tidak akan menemukan versi yang berlaku dan
        -- SEMUA customer_sk jadi NULL.
        -- Solusi: versi PALING AWAL tiap customer diberlakukan surut ke
        -- 1900-01-01, sehingga menutupi seluruh sejarah transaksi. Versi
        -- berikutnya (hasil perubahan nyata) tetap memakai tanggal aslinya.
        case
            when row_number() over (
                     partition by s.customer_id
                     order by s.dbt_valid_from
                 ) = 1
            then timestamp('1900-01-01')
            else cast(s.dbt_valid_from as timestamp)
        end                                                          as effective_start_date,
        cast(coalesce(s.dbt_valid_to, timestamp('9999-12-31 23:59:59'))
             as timestamp)                                           as effective_end_date,
        (s.dbt_valid_to is null)                                     as is_current
    from snap s
)

select
    {{ generate_sk(['v.customer_id', 'v.effective_start_date']) }} as customer_sk,
    v.customer_id,
    v.store_id,
    v.first_name,
    v.last_name,
    concat(v.first_name, ' ', v.last_name)  as full_name,
    v.email,
    a.address,
    a.phone,
    a.district,
    a.postal_code,
    ci.city,
    co.country,
    v.create_date,
    v.is_active,
    v.effective_start_date,
    v.effective_end_date,
    v.is_current,
    v.last_update,
    -- kolom audit ETL
    current_timestamp() as __created_timestamp,
    current_timestamp() as __updated_timestamp
from versioned v
left join address a
    on v.address_id = a.address_id
left join city ci
    on a.city_id = ci.city_id
left join country co
    on ci.country_id = co.country_id
