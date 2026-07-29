with deduped as (
    {{ dedup_by_pk(source('bronze', 'actor'), 'actor_id', 'last_update DESC') }}
)

select
    cast(actor_id    as int64)     as actor_id,
    cast(first_name  as string)    as first_name,
    cast(last_name   as string)    as last_name,
    cast(last_update as timestamp) as last_update
from deduped
where actor_id is not null