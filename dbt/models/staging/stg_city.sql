with deduped as (
    {{ dedup_by_pk(source('bronze', 'city'), 'city_id', 'last_update DESC') }}
)

select
    cast(city_id     as int64)     as city_id,
    cast(city        as string)    as city,
    cast(country_id  as int64)     as country_id,
    cast(last_update as timestamp) as last_update
from deduped
where city_id is not null