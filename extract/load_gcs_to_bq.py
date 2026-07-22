"""
Contoh:
  # transaksi ke partisi
  python extract/load_gcs_to_bq.py --table rental --mode incremental \
      --partition 2007-03-14 --partition-field rental_date

  # dimensi full
  python extract/load_gcs_to_bq.py --table customer --mode full
"""

import argparse
from google.cloud import bigquery

import config
from schemas import SCHEMAS

def build_uri(table, mode, partition):
    if mode == "incremental":
        return f"gs://{config.GCS_BUCKET}/raw/{table}/dt={partition}/data.parquet"
    return f"gs://{config.GCS_BUCKET}/raw/{table}/full/data.parquet"

def apply_schema(job_config, table):
    if table in SCHEMAS:
        job_config.schema = SCHEMAS[table]
        job_config.autodetect = False
    else:
        job_config.autodetect = True
    return job_config

def load(table, mode, partition, partition_field):
    client = bigquery.Client(project=config.GCP_PROJECT_ID, location=config.BQ_LOCATION)
    source_uri = build_uri(table, mode, partition)

    if mode == "incremental":
        if not partition or not partition_field:
            raise SystemExit("[ERROR] not found --partition & --partition-field")
        
        part_suffix = partition.replace("-", "")
        target = f"{config.GCP_PROJECT_ID}.bronze.{table}${part_suffix}"
        job_config = bigquery.LoadJobConfig(
            source_format=bigquery.SourceFormat.PARQUET,
            write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
            time_partitioning=bigquery.TimePartitioning(
                type_=bigquery.TimePartitioningType.DAY,
                field=partition_field,
            ),
        )
        apply_schema(job_config, table)
    else:
        target = f"{config.GCP_PROJECT_ID}.bronze.{table}"
        job_config = bigquery.LoadJobConfig(
            source_format=bigquery.SourceFormat.PARQUET,
            write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
        )
        apply_schema(job_config, table)

    print(f"[LOAD] {source_uri} -> {target}  ({mode})")
    job = client.load_table_from_uri(source_uri, target, job_config=job_config)
    job.result()

    dest = client.get_table(f"{config.GCP_PROJECT_ID}.bronze.{table}")
    print(f"[LOAD] selesai. Tabel bronze.{table} sekarang {dest.num_rows} baris total.")


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--table", required=True)
    p.add_argument("--mode", choices=["incremental", "full"], required=True)
    p.add_argument("--partition", help="YYYY-MM-DD (mode incremental)")
    p.add_argument("--partition-field", help="nama kolom partisi (mode incremental)")
    args = p.parse_args()

    config.validate()
    load(args.table, args.mode, args.partition, args.partition_field)


if __name__ == "__main__":
    main()
