{{ config(materialized='table') }}

with film as (
    select * from {{ ref('stg_film') }}
),

language as (
    select * from {{ ref('stg_language') }}
),

film_category as (
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