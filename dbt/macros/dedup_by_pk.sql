{#
    dedup_by_pk(source_relation, partition_by, order_by)
    -------------------------------------------------------------------------
    - Menghasilkan CTE SELECT yang mengambil SATU baris per primary key
    - Dipakai di semua staging model untuk menangani duplikat PK yang bisa muncul.

    Contoh (stg_customer.sql):
    with deduped as (
        {{ dedup_by_pk(source('bronze','customer'), 'customer_id', 'last_update DESC') }}
    )
    select ... from deduped
#}
{% macro dedup_by_pk(source_relation, partition_by, order_by='last_update DESC') -%}
    select *
    from (
        select
            *,
            row_number() over (
                partition by {{ partition_by }}
                order by {{ order_by }}
            ) as _rn
        from {{ source_relation }}
    )
    where _rn = 1
{%- endmacro %}