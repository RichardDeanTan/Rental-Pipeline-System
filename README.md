# DVD Rental + USD/IDR Data Pipeline

An end-to-end data engineering pipeline that ingests the classic **Pagila / DVD Rental** dataset alongside historical **USD → IDR exchange rates**, transforms it into an analytics-ready star schema on **BigQuery**, and orchestrates the whole flow with **Airflow**. Infrastructure is provisioned as code with **Terraform**, transformations are built with **dbt**, and code quality is guarded by **GitHub Actions CI/CD**.

The project follows a **medallion architecture** (bronze → silver → gold) and is designed so that every layer can be run and tested on its own before being wired into orchestration.

> **Author:** Richard Dean Tanjaya

---

## Architecture

![System Architecture](assets/architecture%20system.png)

Data flows and tool role:

- **PostgreSQL (Docker)** - source system holding DVD rental transactions plus a custom `exchange_rate` table seeded from the Frankfurter API.
- **Python (Extract & Load)** - extracts from Postgres to Parquet, lands it in **GCS**, then loads it into BigQuery `bronze`. Incremental by date for transactions, full-load for dimensions. Idempotent via partition overwrite.
- **Terraform** - provisions the GCS bucket, BigQuery datasets, service account, and IAM.
- **dbt** - transforms `bronze` into `silver` (clean staging) and `gold` (star schema + SCD2), with tests as first-class citizens.
- **Airflow + Cosmos** - orchestrates `simulate → ingest → transform` daily. Cosmos renders each dbt model as its own Airflow task.
- **GitHub Actions** - runs dbt and Terraform checks on every relevant pull request.

---

## Gold Layer (Star Schema)

![Gold Layer Schema](assets/gold%20layer.png)

The gold layer is a galaxy schema: three fact tables sharing conformed dimensions.

| Fact | Grain | Notes |
|---|---|---|
| `fact_rental` | one rental | incremental, partitioned by `rental_date` |
| `fact_payment` | one payment | incremental; `amount_idr` computed with the transaction-month exchange rate |
| `fact_currency_rate` | one rate per validity period | monthly rates expanded into continuous date ranges |

| Dimensions | |
|---|---|
| `dim_customer`, `dim_staff` | **SCD Type 2** (via dbt snapshots) |
| `dim_film`, `dim_store`, `dim_actor`, `dim_date`, `dim_currency` | conformed |
| `bridge_film_actor` | resolves the film↔actor many-to-many, with allocation weights |

---

## Tech Stack

Google Cloud (BigQuery, GCS) · Terraform · Python 3.10 · dbt-bigquery 1.12 · Apache Airflow 2.10 + astronomer-cosmos · Docker · GitHub Actions · PostgreSQL 16

---

## Project Structure

```
dvd-rental-pipeline/
├── terraform/                  # Infrastructure as Code (GCS bucket, BQ datasets, SA, IAM)
│
├── postgres/                   # Source database assets
│   ├── ddl/                    # exchange_rate table DDL
│   ├── scripts/                # seed_exchange_rate.py (Frankfurter API → CSV → Postgres)
│   └── data/                   # dvdrental.tar + generated exchange-rate CSVs
│
├── extract/                    # Extract & Load (Python, standalone-runnable)
│   ├── extract_postgres.py     # Postgres → Parquet → GCS (incremental / full)
│   ├── extract_fx_api.py       # daily FX from API → GCS
│   ├── load_gcs_to_bq.py       # Parquet in GCS → BigQuery bronze (idempotent)
│   ├── run_backfill.py         # orchestrates dimension full-loads & transaction backfills
│   ├── schemas.py              # explicit BigQuery schemas (type contracts)
│   ├── tables_config.py        # single source of truth for tables data types & config
│   ├── config.py               # central config / connections
│   └── requirements.txt        # pinned Python dependencies
│
├── simulator/                  # generate_daily_rentals.py (injects new dated rentals+payments)
│
├── dbt/                        # Transformations
│   ├── models/
│   │   ├── staging/            # silver: one stg_* view per source table
│   │   └── gold/               # gold: dim_*, fact_*, bridge_*
│   ├── snapshots/              # SCD2 snapshots (customer, staff)
│   ├── macros/                 # reusable SQL (surrogate keys, dedup, schema naming)
│   ├── dbt_project.yml
│   ├── profiles.yml            # BigQuery connection (git-ignored)
│   └── packages.yml            # dbt_utils, dbt_expectations
│
├── airflow/                    # Orchestration
│   ├── dags/                   # DAGs + helpers + Teams failure callback
│   ├── config/                 # container-specific dbt profiles.yml
│   ├── Dockerfile              # Airflow image + dbt in an isolated venv
│   ├── docker-compose.yml      # scheduler, webserver, metadata DB
│   └── .env.example            # Postgres/GCP connection vars
│
├── .github/
│   └── workflows/              # ci.yml (dbt) + terraform.yml (plan/apply)
│
├── assets/                     # architecture & schema diagrams
└── secrets/                    # service account keys (git-ignored)
```

> NOTE: Only certain files are listed. Inside `dbt/models/` there are ~15 staging models and ~11 gold models

---

## Key Design Decisions

- **Medallion architecture:** `bronze` (raw), `silver` (typed, cleaned, deduped views), `gold` (business-ready star schema).
- **Idempotency everywhere:** incremental loads use `WRITE_TRUNCATE` into date partitions, dbt facts use `is_incremental()`. Re-running the same date changes nothing.
- **Backfill = incremental triggered into the past:** the exact same DAGs replay historical dates via `airflow dags backfill`. No special backfill code.
- **SCD Type 2:** `dim_customer` and `dim_staff` track history through dbt snapshots, facts resolve to the correct historical version by `date BETWEEN effective_start AND effective_end`.
- **Currency conversion:** payments are converted to IDR using the rate of the **transaction's month**, not today's rate. Monthly rates are expanded into continuous, gapless date ranges so every payment always finds a rate.
- **FK strategy:** facts carry natural `*_id` for easy querying, plus surrogate `*_sk` only where SCD2 requires version-accurate joins.
- **Explicit type contracts:** `schemas.py` locks BigQuery column types so all-NULL columns can't be mis-inferred across partitions.

---

## Running It From Scratch

Each step is runnable and testable on its own:

1. **Infrastructure** - `terraform apply` (bucket, datasets, service account, IAM).
2. **Source data** - restore `dvdrental.tar` into Postgres, seed exchange rates.
3. **Ingest** - `run_backfill.py dimensions` then backfill transaction tables into `bronze`.
4. **Transform** - `dbt build` (silver → gold) and `dbt snapshot` (SCD2).
5. **Orchestrate** - `docker compose up` in `airflow/`, then trigger the DAGs.
6. **CI/CD** - push a PR; GitHub Actions runs dbt build/tests against the `dbt_ci` dataset.

Step-by-step guides with checkpoints live alongside each component.

---

## CI/CD

Two GitHub Actions workflows run on pull requests:

- **dbt CI:** `dbt deps → compile → build --target ci`, building all models and running all tests in an isolated `dbt_ci` dataset (reads shared `bronze`).
- **Terraform CI:** `plan` on PRs (posted as a comment), guarded so infrastructure changes are previewed before merge.

CI tests **code, not data** → so it stays valuable even with a dummy dataset. Airflow itself isn't executed in CI; it only orchestrates already-tested dbt models and Python scripts.

---

## Known Limitations

- The rental data is a static teaching dataset; the simulator adds synthetic present-day activity to exercise the incremental path.
- `dim_date.is_holiday` is always `false` (no external holiday calendar wired in).
- Terraform uses local state; remote state (GCS backend) is a planned improvement that would make CI `apply` safe.
- Exchange rates are monthly granularity by design, kept simple and easy.