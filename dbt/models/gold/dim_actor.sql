{{ config(materialized='table') }}

select
    {{ generate_sk(['actor_id']) }}     as actor_sk,
    actor_id,
    first_name,
    last_name,
    concat(first_name, ' ', last_name)  as full_name,
    last_update
from {{ ref('stg_actor') }}