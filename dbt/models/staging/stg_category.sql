with deduped as (
    {{ dedup_by_pk(source('bronze', 'category'), 'category_id', 'last_update DESC') }}
)

select
    cast(category_id as int64)     as category_id,
    cast(name        as string)    as category_name,
    cast(last_update as timestamp) as last_update
from deduped
where category_id is not null