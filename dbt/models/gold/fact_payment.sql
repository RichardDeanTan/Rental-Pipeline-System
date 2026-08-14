{{ config(
    materialized='incremental',
    unique_key='payment_id',
    partition_by={'field': 'payment_date', 'data_type': 'date'},
    cluster_by=['customer_id', 'film_id']
) }}

with payment as (
    select * from {{ ref('stg_payment') }}

    {% if is_incremental() %}
    {% if var('start_date', none) is not none and var('end_date', none) is not none %}
    where date(payment_date) >= '{{ var("start_date") }}'
      and date(payment_date) <  '{{ var("end_date") }}'
    {% else %}
    where date(payment_date) >= (
        select coalesce(max(payment_date), date '1900-01-01')
        from {{ this }}
    )
    {% endif %}
    {% endif %}
),

rental as (
    select rental_id, inventory_id from {{ ref('stg_rental') }}
),

inventory as (
    select * from {{ ref('stg_inventory') }}
),

currency_rate as (
    select
        rate_value,
        effective_start_date,
        effective_end_date
    from {{ ref('fact_currency_rate') }}
    where currency_code = 'IDR'
),

dim_customer as (
    select customer_sk, customer_id, effective_start_date, effective_end_date
    from {{ ref('dim_customer') }}
),

dim_staff as (
    select staff_sk, staff_id, effective_start_date, effective_end_date
    from {{ ref('dim_staff') }}
),

usd as (
    select currency_sk from {{ ref('dim_currency') }} where currency_code = 'USD'
)

select
    {{ generate_sk(['p.payment_id']) }} as payment_sk,
    p.payment_id,
    dc.customer_sk,
    p.customer_id,
    dstf.staff_sk,
    p.staff_id,

    i.film_id,
    i.store_id,

    p.rental_id,

    (select currency_sk from usd)                                 as currency_sk,
    cast(format_date('%Y%m%d', date(p.payment_date)) as int64)    as payment_date_id,
    date(p.payment_date)                                          as payment_date,
    -- measures
    p.amount                                                      as amount_usd,
    cr.rate_value                                                 as amount_idr_rate,
    -- konversi ke IDR
    cast(p.amount * cr.rate_value as numeric)                     as amount_idr,

    -- flag data
    (cr.rate_value is not null)                                   as has_rate,
    (p.rental_id is not null)                                     as has_rental,

    current_timestamp()                                           as __created_timestamp

from payment p
left join rental r
    on p.rental_id = r.rental_id
left join inventory i
    on r.inventory_id = i.inventory_id
left join currency_rate cr
    on date(p.payment_date) between cr.effective_start_date and cr.effective_end_date
left join dim_customer dc
    on  p.customer_id = dc.customer_id
    and p.payment_date between dc.effective_start_date and dc.effective_end_date
left join dim_staff dstf
    on  p.staff_id = dstf.staff_id
    and p.payment_date between dstf.effective_start_date and dstf.effective_end_date