{{ config(
    materialized='incremental',
    unique_key='rental_id',
    partition_by={'field': 'rental_date', 'data_type': 'date'},
    cluster_by=['customer_id', 'film_id']
) }}

with rental as (
    select * from {{ ref('stg_rental') }}

    {% if is_incremental() %}
    {% if var('start_date', none) is not none and var('end_date', none) is not none %}
    where date(rental_date) >= '{{ var("start_date") }}'
      and date(rental_date) <  '{{ var("end_date") }}'
    {% else %}
    where date(rental_date) >= (
        select coalesce(max(rental_date), date '1900-01-01')
        from {{ this }}
    )
    {% endif %}
    {% endif %}
),

inventory as (
    select * from {{ ref('stg_inventory') }}
),

payment_agg as (
    select
        rental_id,
        true        as is_paid,
        count(*)    as payment_count,
        sum(amount) as total_paid_usd
    from {{ ref('stg_payment') }}
    where rental_id is not null
    group by rental_id
),

dim_customer as (
    select customer_sk, customer_id, effective_start_date, effective_end_date
    from {{ ref('dim_customer') }}
),

dim_staff as (
    select staff_sk, staff_id, effective_start_date, effective_end_date
    from {{ ref('dim_staff') }}
)

select
    {{ generate_sk(['r.rental_id']) }}                          as rental_sk,
    r.rental_id,

    dc.customer_sk,
    r.customer_id,
    ds.staff_sk,
    r.staff_id,

    i.film_id,
    i.store_id,
    r.inventory_id,

    cast(format_date('%Y%m%d', date(r.rental_date)) as int64)   as rental_date_id,
    cast(format_date('%Y%m%d', date(r.return_date)) as int64)   as return_date_id,

    date(r.rental_date)                                         as rental_date,
    date(r.return_date)                                         as return_date,

    -- measures
    date_diff(date(r.return_date), date(r.rental_date), day)    as actual_rental_duration,
    (r.return_date is not null)                                 as is_returned,
    coalesce(pa.is_paid, false)                                 as is_paid,
    coalesce(pa.payment_count, 0)                               as payment_count,
    coalesce(pa.total_paid_usd, cast(0 as numeric))             as total_paid_usd,

    r.last_update,
    current_timestamp()                                         as __created_timestamp

from rental r
inner join inventory i
    on r.inventory_id = i.inventory_id
left join payment_agg pa
    on r.rental_id = pa.rental_id
left join dim_customer dc
    on  r.customer_id = dc.customer_id
    and r.rental_date between dc.effective_start_date and dc.effective_end_date
left join dim_staff ds
    on  r.staff_id = ds.staff_id
    and r.rental_date between ds.effective_start_date and ds.effective_end_date