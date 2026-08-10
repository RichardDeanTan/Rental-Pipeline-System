with deduped as (
    {{ dedup_by_pk(source('bronze', 'rental'), 'rental_id', 'last_update DESC') }}
)

select
    cast(rental_id    as int64)     as rental_id,
    cast(inventory_id as int64)     as inventory_id,
    cast(customer_id  as int64)     as customer_id,
    cast(staff_id     as int64)     as staff_id,
    cast(rental_date  as timestamp) as rental_date,
    cast(return_date  as timestamp) as return_date,
    cast(last_update  as timestamp) as last_update
from deduped
where rental_id is not null