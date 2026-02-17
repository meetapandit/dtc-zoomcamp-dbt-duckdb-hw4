{{
    config(
        materialized='table',
    )
}}

{% set columns = [
    'tripid',
    'vendorid',
    'ratecodeid',
    'pickup_locationid',
    'dropoff_locationid',
    'pickup_datetime',
    'dropoff_datetime',
    'store_and_fwd_flag',
    'passenger_count',
    'trip_distance',
    'fare_amount',
    'extra',
    'mta_tax',
    'tip_amount',
    'tolls_amount',
    'ehail_fee',
    'improvement_surcharge',
    'total_amount',
    'payment_type',
    'payment_type_description',
    'trip_type',
    'congestion_surcharge'
] %}

WITH green_tripdata AS (
    SELECT {{ columns | join(', ') }}
         , 'green_trips' AS service_type
    FROM {{ ref('stg_green_tripdata') }}
)

, yellow_tripdata AS (
    SELECT {{ columns | join(', ') }}
         , 'yellow_trips' AS service_type
    FROM {{ ref('stg_yellow_tripdata') }}
)
, trips_unioned AS (
    SELECT * FROM green_tripdata
    UNION ALL
    SELECT * FROM yellow_tripdata
)
, dim_zones AS (
    SELECT * FROM {{ ref('dim_zones') }}
    WHERE  borough != 'Unknown'
)

SELECT 
    t.tripid,
    t.vendorid,
    t.ratecodeid,
    t.pickup_locationid,
    t.dropoff_locationid,
    t.pickup_datetime,
    t.dropoff_datetime,
    t.store_and_fwd_flag,
    t.passenger_count,
    t.trip_distance,
    t.fare_amount,
    t.extra,
    t.mta_tax,
    t.tip_amount,
    t.tolls_amount,
    t.ehail_fee,
    t.improvement_surcharge,
    t.total_amount,
    t.payment_type,
    t.payment_type_description,
    t.trip_type,
    {{ get_trip_duration_minutes('t.pickup_datetime', 't.dropoff_datetime') }} as trip_duration_minutes,
    t.congestion_surcharge,

    dz_pickup.borough AS pickup_borough,
    dz_pickup.zone AS pickup_zone,
    dz_dropoff.borough AS dropoff_borough,
    dz_dropoff.zone AS dropoff_zone,
    t.service_type

FROM trips_unioned t
INNER JOIN dim_zones dz_pickup
    ON t.pickup_locationid = dz_pickup.location_id
INNER JOIN dim_zones dz_dropoff
    ON t.dropoff_locationid = dz_dropoff.location_id


{% if is_incremental() %}
  -- Only process new trips based on pickup datetime
  where t.pickup_datetime > (select max(pickup_datetime) from {{ this }})
{% endif %}