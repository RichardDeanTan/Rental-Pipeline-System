with deduped as (
    {{ dedup_by_pk(source('bronze', 'payment'), 'payment_id', 'payment_date DESC') }}
)

select
    cast(payment_id   as int64)     as payment_id,
    cast(customer_id  as int64)     as customer_id,
    cast(staff_id     as int64)     as staff_id,
    cast(rental_id    as int64)     as rental_id,
    cast(amount       as numeric)   as amount,
    cast(payment_date as timestamp) as payment_date
from deduped
where payment_id is not null