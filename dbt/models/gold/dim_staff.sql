{{ config(materialized='table') }}

with snap as (
    select * from {{ ref('scd_staff') }}
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
        s.staff_id,
        s.first_name,
        s.last_name,
        s.email,
        s.username,
        s.store_id,
        s.address_id,
        s.is_active,
        s.last_update,
        case
            when row_number() over (
                     partition by s.staff_id
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
    {{ generate_sk(['v.staff_id', 'v.effective_start_date']) }} as staff_sk,
    v.staff_id,
    v.first_name,
    v.last_name,
    concat(v.first_name, ' ', v.last_name)  as full_name,
    v.email,
    v.username,
    v.store_id,
    a.address,
    ci.city,
    co.country,
    v.is_active,
    v.effective_start_date,
    v.effective_end_date,
    v.is_current,
    v.last_update,
    current_timestamp() as __created_timestamp,
    current_timestamp() as __updated_timestamp
from versioned v
left join address a
    on v.address_id = a.address_id
left join city ci
    on a.city_id = ci.city_id
left join country co
    on ci.country_id = co.country_id