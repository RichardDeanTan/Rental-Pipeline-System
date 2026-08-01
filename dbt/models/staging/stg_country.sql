with deduped as (
    {{ dedup_by_pk(source('bronze', 'country'), 'country_id', 'last_update DESC') }}
)

select
    cast(country_id  as int64)     as country_id,
    cast(country     as string)    as country,
    cast(last_update as timestamp) as last_update
from deduped
where country_id is not null