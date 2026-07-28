-- TEST: mendeteksi FAN TRAP di fact_rental
-- SUCCESS --> 0 baris.

select
    rental_id,
    count(*) as row_count
from {{ ref('fact_rental') }}
group by rental_id
having count(*) > 1