with deduped as (
    {{ dedup_by_pk(source('bronze', 'staff'), 'staff_id', 'last_update DESC') }}
)

select
    cast(staff_id    as int64)     as staff_id,
    cast(first_name  as string)    as first_name,
    cast(last_name   as string)    as last_name,
    cast(email       as string)    as email,
    cast(address_id  as int64)     as address_id,
    cast(store_id    as int64)     as store_id,
    cast(username    as string)    as username,
    cast(active      as bool)      as is_active,
    cast(last_update as timestamp) as last_update
from deduped
where staff_id is not null