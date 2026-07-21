"""
Contoh:
- python extract/extract_postgres.py --table rental --mode incremental --date-col rental_date --start 2007-03-14 --end 2007-03-15
- python extract/extract_postgres.py --table customer --mode full
"""

import argparse
import pandas as pd
from sqlalchemy import create_engine

import config


def extract(table, mode, date_col, start, end):
    engine = create_engine(config.pg_conn_string())

    if mode == "incremental":
        if not date_col or not start or not end:
            raise SystemExit("[ERROR] mode incremental butuh --date-col, --start, --end")
        
        query = f'SELECT * FROM "{table}" WHERE "{date_col}" >= %(start)s AND "{date_col}" < %(end)s'
        params = {"start": start, "end": end}
        print(f"[EXTRACT] {table} - incremental {start} -> {end}")

        df = pd.read_sql(query, engine, params=params)
    else:
        query = f'SELECT * FROM "{table}"'
        print(f"[EXTRACT] {table} - full load")

        df = pd.read_sql(query, engine)

    print(f"[EXTRACT] {len(df)} from {table}")
    
    return df


def gcs_path(table, mode, start):
    if mode == "incremental":
        return f"raw/{table}/dt={start}/data.parquet"
    return f"raw/{table}/full/data.parquet"


def upload_parquet(df, blob_path):
    full_uri = f"gs://{config.GCS_BUCKET}/{blob_path}"
    if df.empty:
        print(f"[SKIP] df empty.")
        return None
    
    df.to_parquet(
        full_uri, 
        index=False, 
        engine="pyarrow",
        coerce_timestamps="us",
        allow_truncated_timestamps=True)
    print(f"[UPLOAD] {len(df)} baris -> {full_uri}")
    return full_uri


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--table", required=True)
    p.add_argument("--mode", choices=["incremental", "full"], required=True)
    p.add_argument("--date-col", help="kolom tanggal (mode incremental)")
    p.add_argument("--start", help="tanggal mulai YYYY-MM-DD (inclusive)")
    p.add_argument("--end", help="tanggal akhir YYYY-MM-DD (exclusive)")
    args = p.parse_args()

    config.validate()
    df = extract(args.table, args.mode, args.date_col, args.start, args.end)
    blob = gcs_path(args.table, args.mode, args.start)
    upload_parquet(df, blob)


if __name__ == "__main__":
    main()
