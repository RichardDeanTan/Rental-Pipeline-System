-- TEST: SCD2 gak ada duplicate.
-- SUCCESS --> 0 baris.

with numbered as (
    select
        customer_id,
        effective_start_date,
        effective_end_date,
        lead(effective_start_date) over (
            partition by customer_id
            order by effective_start_date
        ) as next_start_date
    from {{ ref('dim_customer') }}
)

select
    customer_id,
    effective_start_date,
    effective_end_date,
    next_start_date
from numbered
where next_start_date is not null
  and effective_end_date >= next_start_date
