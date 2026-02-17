# DTC Zoomcamp Module 4 - dbt with BigQuery (Dockerized)

This project uses dbt running in Docker to transform NYC taxi trip data stored in Google Cloud Storage into analytics-ready tables in BigQuery.

## Architecture

```
GCS (csv.gz files) → BigQuery External Tables → dbt Staging Views → dbt Core Tables
```

## Project Structure

```
├── Dockerfile                  # Python 3.12 + uv + dbt-bigquery
├── docker-compose.yml          # Docker service with volume mounts
├── requirements.txt            # dbt-bigquery, requests
├── keys/                       # GCP service account key (gitignored)
└── taxi_rides_ny/
    ├── dbt_project.yml         # dbt project config
    ├── profiles.yml            # BigQuery connection (dev/prod)
    ├── packages.yml            # dbt_utils, dbt_external_tables
    ├── seeds/
    │   └── taxi_zone_lookup.csv
    ├── macros/
    │   ├── get_payment_type_description.sql
    │   └── get_trip_duration_minutes.sql
    └── models/
        ├── staging/
        │   ├── sources.yml              # External sources from GCS
        │   ├── schema.yml               # Column tests
        │   ├── stg_green_tripdata.sql   # Green taxi staging
        │   └── stg_yellow_tripdata.sql  # Yellow taxi staging
        └── core/
            ├── dim_zones.sql                # Zone dimension (from seed)
            ├── fact_trips.sql               # Unified trip facts
            └── fct_monthly_zone_revenue.sql # Monthly revenue aggregation
```

## Model Lineage

```
seeds/taxi_zone_lookup.csv
    → dim_zones

sources (GCS external tables)
    → stg_green_tripdata  ─┐
    → stg_yellow_tripdata ─┤
                           ├→ fact_trips → fct_monthly_zone_revenue
    dim_zones ─────────────┘
```

## Prerequisites

1. Docker installed
2. GCP service account JSON key with BigQuery Data Editor and BigQuery Job User roles
3. CSV.gz taxi data uploaded to GCS bucket (`gs://dezoomcamp_hw3_2026_mp/`)

## Setup

1. Place your GCP service account key:
   ```bash
   mkdir -p keys
   cp /path/to/your-key.json keys/service-account.json
   ```

2. Build the Docker image:
   ```bash
   docker compose build
   ```

## How to Run

```bash
# 1. Verify BigQuery connection
docker compose run --rm dbt debug

# 2. Install dbt packages (dbt_utils, dbt_external_tables)
docker compose run --rm dbt deps

# 3. Create external tables in BigQuery from GCS files
docker compose run --rm dbt run-operation stage_external_sources --args '{"select": "staging"}'

# 4. Load seed data (taxi_zone_lookup)
docker compose run --rm dbt seed

# 5. Build all models and run tests
docker compose run --rm dbt build

# 6. Build for production
docker compose run --rm dbt build --target prod
```

## Useful Commands

```bash
# Compile SQL without executing
docker compose run --rm dbt compile

# Run a specific model
docker compose run --rm dbt run --select fact_trips

# Run with test data (limited rows)
docker compose run --rm dbt build --select stg_green_tripdata --vars '{"is_test_run": "true"}'

# Clean build artifacts
docker compose run --rm dbt clean

# Remove orphan Docker containers
docker container prune -f
```

---

## Homework Answers

### Question 1. dbt Lineage and Execution
- If you run dbt run --select int_trips_unioned, what models will be built?
    - int_trips_unioned only

### Question 2. dbt Tests
- Your model fct_trips has been running successfully for months. A new value 6 now appears in the source data.
- What happens when you run dbt test --select fct_trips?
    - dbt will fail the test, returning a non-zero exit code

### Question 3. Counting Records in fct_monthly_zone_revenue
- After running your dbt project, query the fct_monthly_zone_revenue model.
- What is the count of records in the fct_monthly_zone_revenue model?
    - 12,998

### Question 4. Best Performing Zone for Green Taxis (2020)
- Using the fct_monthly_zone_revenue table, find the pickup zone with the highest total revenue (revenue_monthly_total_amount) for Green taxi trips in 2020.
- Which zone had the highest revenue?
    - East Harlem North

### Question 5. Green Taxi Trip Counts (October 2019)
- Using the fct_monthly_zone_revenue table, what is the total number of trips (total_monthly_trips) for Green taxis in October 2019?
    - 384,624

### Question 6. Build a Staging Model for FHV Data
- Create a staging model for the For-Hire Vehicle (FHV) trip data for 2019.
- What is the count of records in stg_fhv_tripdata?
    - 43,244,693
