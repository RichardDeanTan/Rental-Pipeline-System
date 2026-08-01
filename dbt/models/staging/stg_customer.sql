with deduped as (
    {{ dedup_by_pk(source('bronze', 'customer'), 'customer_id', 'last_update DESC') }}
)

select
    cast(customer_id as int64)     as customer_id,
    cast(store_id    as int64)     as store_id,
    cast(first_name  as string)    as first_name,
    cast(last_name   as string)    as last_name,
    cast(email       as string)    as email,
    cast(address_id  as int64)     as address_id,
    cast(activebool  as bool)      as is_active,
    cast(create_date as date)      as create_date,
    cast(last_update as timestamp) as last_update
from deduped
where customer_id is not null