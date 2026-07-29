with deduped as (
    {{ dedup_by_pk(source('bronze', 'address'), 'address_id', 'last_update DESC') }}
)

select
    cast(address_id  as int64)     as address_id,
    cast(address     as string)    as address,
    cast(address2    as string)    as address2,
    cast(district    as string)    as district,
    cast(city_id     as int64)     as city_id,
    cast(postal_code as string)    as postal_code,
    cast(phone       as string)    as phone,
    cast(last_update as timestamp) as last_update
from deduped
where address_id is not null