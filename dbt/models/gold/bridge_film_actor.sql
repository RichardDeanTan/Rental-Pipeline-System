-- bridge_film_actor
--
-- Satu baris = satu pasangan film-aktor.
--
-- weight:
--  weight = 1 / jumlah_aktor_film_itu, sehingga alokasi proporsional bisa
--  dihitung: SUMX(bridge, fact_payment[amount_usd] * bridge[weight]).

{{ config(materialized='table') }}

with film_actor as (
    select * from {{ ref('stg_film_actor') }}
),

actor_counts as (
    select
        film_id,
        count(*) as actor_count
    from film_actor
    group by film_id
)

select
    {{ generate_sk(['fa.film_id']) }}                    as film_sk,
    {{ generate_sk(['fa.actor_id']) }}                   as actor_sk,
    fa.film_id,
    fa.actor_id,
    ac.actor_count,
    cast(safe_divide(1.0, ac.actor_count) as numeric)    as weight
from film_actor fa
left join actor_counts ac
    on fa.film_id = ac.film_id