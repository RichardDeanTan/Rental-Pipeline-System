with deduped as (
    {{ dedup_by_pk(source('bronze', 'film_actor'), 'film_id, actor_id', 'last_update DESC') }}
)

select
    cast(film_id     as int64)     as film_id,
    cast(actor_id    as int64)     as actor_id,
    cast(last_update as timestamp) as last_update
from deduped
where film_id is not null
    and actor_id is not null