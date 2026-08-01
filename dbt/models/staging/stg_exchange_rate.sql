with deduped as (
    {{ dedup_by_pk(source('bronze', 'exchange_rate'), 'rate_date', 'loaded_at DESC') }}
)

select
    cast(rate_date as date)      as rate_date,
    cast(currency  as string)    as currency,
    cast(rate      as numeric)   as rate,
    cast(loaded_at as timestamp) as loaded_at
from deduped
where rate_date is not null