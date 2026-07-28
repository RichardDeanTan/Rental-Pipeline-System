-- TEST: gak boleh ada payment yang gak dapet kurs
-- SUCCESS -->  0 baris.

select
    payment_id,
    payment_date,
    amount_usd
from {{ ref('fact_payment') }}
where amount_idr_rate is null
