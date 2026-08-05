with deduped as (
    {{ dedup_by_pk(source('bronze', 'inventory'), 'inventory_id', 'last_update DESC') }}
)

select
    cast(inventory_id as int64)     as inventory_id,
    cast(film_id      as int64)     as film_id,
    cast(store_id     as int64)     as store_id,
    cast(last_update  as timestamp) as last_update
from deduped
where inventory_id is not null