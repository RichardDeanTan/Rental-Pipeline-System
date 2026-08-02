with deduped as (
    {{ dedup_by_pk(source('bronze', 'film_category'), 'film_id, category_id', 'last_update DESC') }}
)

select
    cast(film_id     as int64)     as film_id,
    cast(category_id as int64)     as category_id,
    cast(last_update as timestamp) as last_update
from deduped
where film_id is not null
    and category_id is not null