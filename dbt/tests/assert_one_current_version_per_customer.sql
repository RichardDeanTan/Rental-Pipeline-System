-- TEST: setiap customer harus punya 1 versi newest
-- SUCCESS --> 0 baris.

select
    customer_id,
    countif(is_current) as current_versions
from {{ ref('dim_customer') }}
group by customer_id
having countif(is_current) <> 1
