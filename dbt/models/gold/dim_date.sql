-- dim_date : dimensi kalender, DIGENERATE (bukan dari OLTP).
-- Range 2005-01-01 s/d 2030-12-31 — menutup seluruh rental_date, return_date,
-- payment_date, plus margin untuk data simulator masa kini.
-- date_id adalah SMART KEY (YYYYMMDD) — nilainya bermakna & sortable, tidak di-hash.

{{ config(materialized='table') }}

with date_spine as (
    select d
    from unnest(generate_date_array('2005-01-01', '2030-12-31', interval 1 day)) as d
)

select
    cast(format_date('%Y%m%d', d) as int64)   as date_id,
    d                                          as date,
    extract(day     from d)                    as day,
    extract(month   from d)                    as month,
    extract(year    from d)                    as year,
    format_date('%A', d)                       as day_name,
    format_date('%B', d)                       as month_name,
    extract(quarter from d)                    as quarter,
    extract(dayofweek from d)                  as day_of_week,   -- 1=Minggu .. 7=Sabtu
    extract(dayofweek from d) in (1, 7)        as is_weekend,
    -- is_holiday tidak bisa diturunkan dari tanggal saja; butuh kalender libur
    -- eksternal. Default FALSE, didokumentasikan sebagai known limitation.
    false                                      as is_holiday,
    -- kolom bantu untuk agregasi bulanan (dipakai join kurs bulanan)
    date_trunc(d, month)                       as month_start_date
from date_spine
