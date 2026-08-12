-- dim_film : satu baris per film.
-- Meratakan (flatten) snowflake: film -> language, dan film -> film_category -> category.
--
-- CATATAN: special_features (RECORD) & fulltext (tsvector) sudah di-DROP sejak
-- silver, jadi tidak muncul di sini. rental_duration sudah bernama
-- allowed_rental_duration untuk membedakannya dari durasi sewa AKTUAL
-- (yang dihitung di fact_rental sebagai actual_rental_duration).
--
-- film_category dipakai LEFT JOIN (bukan INNER) agar film tanpa kategori tidak
-- hilang dari dimensi — dimensi tidak boleh kehilangan anggota.

{{ config(materialized='table') }}

with film as (
    select * from {{ ref('stg_film') }}
),

language as (
    select * from {{ ref('stg_language') }}
),

film_category as (
    -- GUARD: kalau suatu film ternyata punya >1 kategori, ambil satu saja
    -- (kategori dengan id terkecil) agar grain dim_film tetap 1 baris per film.
    -- Di dataset ini tiap film hanya punya 1 kategori, jadi guard ini
    -- praktis tidak mengubah apa pun — tapi mencegah dimensi pecah diam-diam
    -- kalau data berubah. Kalau nanti multi-kategori jadi kebutuhan nyata,
    -- pola yang benar adalah bridge table (seperti bridge_film_actor).
    select
        film_id,
        min(category_id) as category_id
    from {{ ref('stg_film_category') }}
    group by film_id
),

category as (
    select * from {{ ref('stg_category') }}
)

select
    {{ generate_sk(['f.film_id']) }}    as film_sk,
    f.film_id,
    f.title,
    f.description,
    f.release_year,
    l.language_name,
    c.category_name,
    f.allowed_rental_duration,
    f.rental_rate,
    f.length,
    f.replacement_cost,
    f.rating,
    f.last_update
from film f
left join language l
    on f.language_id = l.language_id
left join film_category fc
    on f.film_id = fc.film_id
left join category c
    on fc.category_id = c.category_id
