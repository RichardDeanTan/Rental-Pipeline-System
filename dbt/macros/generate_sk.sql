{#
    generate_sk(columns)
    -------------------------------------------------------------------------
    Membuat surrogate key dengan TO_BASE64(SHA256(...))
#}
{% macro generate_sk(columns) -%}
    {%- set parts = [] -%}
    {%- for col in columns -%}
        {%- set _ = parts.append("COALESCE(CAST(" ~ col ~ " AS STRING), '__NULL__')") -%}
    {%- endfor -%}
    TO_BASE64(SHA256(
        {{ parts | join(" || '||' || ") }}
    ))
{%- endmacro %}
