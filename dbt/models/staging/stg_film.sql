with deduped as (
    {{ dedup_by_pk(source('bronze', 'film'), 'film_id', 'last_update DESC') }}
)

select
    cast(film_id          as int64)   as film_id,
    cast(title            as string)  as title,
    cast(description      as string)  as description,
    cast(release_year     as int64)   as release_year,
    cast(language_id      as int64)   as language_id,
    cast(rental_duration  as int64)   as allowed_rental_duration,
    cast(rental_rate      as numeric) as rental_rate,
    cast(length           as int64)   as length,
    cast(replacement_cost as numeric) as replacement_cost,
    cast(rating           as string)  as rating,
    cast(last_update      as timestamp) as last_update
from deduped
where film_id is not null