{{ config(materialized='table') }}

with currencies as (
    select 'USD'        as currency_code,
    'US Dollar'         as currency_name
    union all
    select 'IDR'        as currency_code,
    'Indonesian Rupiah' as currency_name
)

select
    {{ generate_sk(['currency_code']) }} as currency_sk,
    currency_code,
    currency_name
from currencies