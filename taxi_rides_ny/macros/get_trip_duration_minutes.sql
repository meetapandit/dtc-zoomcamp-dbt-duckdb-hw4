{% macro get_trip_duration_minutes(start_time, end_time) -%}
    TIMESTAMP_DIFF({{ end_time }}, {{ start_time }}, MINUTE)
{%- endmacro %}