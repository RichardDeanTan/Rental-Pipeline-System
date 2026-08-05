with deduped as (
    {{ dedup_by_pk(source('bronze', 'language'), 'language_id', 'last_update DESC') }}
)

select
    cast(language_id as int64)     as language_id,
    cast(name        as string)    as language_name,
    cast(last_update as timestamp) as last_update
from deduped
where language_id is not null