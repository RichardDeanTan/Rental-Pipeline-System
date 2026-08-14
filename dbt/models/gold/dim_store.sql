{{ config(materialized='table') }}

with store as (
    select * from {{ ref('stg_store') }}
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

staff as (
    select * from {{ ref('stg_staff') }}
)

select
    {{ generate_sk(['s.store_id']) }}           as store_sk,
    s.store_id,
    s.manager_staff_id,
    concat(st.first_name, ' ', st.last_name)    as manager_name,
    a.address,
    a.district,
    a.postal_code,
    a.phone,
    ci.city,
    co.country,
    s.last_update
from store s
left join address a
    on s.address_id = a.address_id
left join city ci
    on a.city_id = ci.city_id
left join country co
    on ci.country_id = co.country_id
left join staff st
    on s.manager_staff_id = st.staff_id