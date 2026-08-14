{{ config(materialized='table') }}

with rates as (
    select * from {{ ref('stg_exchange_rate') }}
),

ranged as (
    select
        rate_date,
        currency    as currency_code,
        rate        as rate_value,
        loaded_at,
        case
            when row_number() over (
                     partition by currency order by rate_date
                 ) = 1
            then date '1900-01-01'
            else rate_date
        end as effective_start_date,
        coalesce(
            date_sub(
                lead(rate_date) over (partition by currency order by rate_date),
                interval 1 day
            ),
            date '9999-12-31'
        ) as effective_end_date
    from rates
)

select
    {{ generate_sk(['r.currency_code', 'r.effective_start_date']) }}    as currency_rate_sk,
    c.currency_sk,
    r.currency_code,
    r.rate_value,
    r.rate_date,
    r.effective_start_date,
    r.effective_end_date,
    (r.effective_end_date = date '9999-12-31')                          as is_current,
    r.loaded_at
from ranged r
left join {{ ref('dim_currency') }} c
    on r.currency_code = c.currency_code