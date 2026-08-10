with deduped as (
    {{ dedup_by_pk(source('bronze', 'store'), 'store_id', 'last_update DESC') }}
)

select
    cast(store_id         as int64)     as store_id,
    cast(manager_staff_id as int64)     as manager_staff_id,
    cast(address_id       as int64)     as address_id,
    cast(last_update      as timestamp) as last_update
from deduped
where store_id is not null