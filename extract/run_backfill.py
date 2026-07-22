"""
  1) Full-load semua tabel dimensi (sekali jalan):
       python extract/run_backfill.py dimensions

  2) Backfill tabel transaksi untuk rentang tanggal:
       python extract/run_backfill.py transactions --table rental \
           --start 2005-05-24 --end 2005-05-31
     (--end exclusive; loop per hari)
"""

import argparse
from datetime import datetime, timedelta

import config
import tables_config as tcfg
import extract_postgres as ep
import load_gcs_to_bq as lb


def daterange(start, end):
    d0 = datetime.strptime(start, "%Y-%m-%d")
    d1 = datetime.strptime(end, "%Y-%m-%d")
    cur = d0
    while cur < d1:
        yield cur.strftime("%Y-%m-%d")
        cur += timedelta(days=1)

def do_full(table):
    print(f"\n{'='*60}\n[FULL] {table}\n{'='*60}")
    df = ep.extract(table, "full", None, None, None)
    blob = ep.gcs_path(table, "full", None)
    ep.upload_parquet(df, blob)
    lb.load(table, "full", None, None)

def do_incremental_day(table, date_col, day):
    end = (datetime.strptime(day, "%Y-%m-%d") + timedelta(days=1)).strftime("%Y-%m-%d")
    df = ep.extract(table, "incremental", date_col, day, end)
    blob = ep.gcs_path(table, "incremental", day)
    uri = ep.upload_parquet(df, blob)
    if uri:
        lb.load(table, "incremental", day, date_col)
    else:
        print(f"[SKIP LOAD] {table} {day} - tidak ada data")

def cmd_dimensions(args):
    config.validate()
    tables = list(tcfg.DIMENSION_TABLES.keys())
    print(f"Full-load {len(tables)} tabel dimensi: {tables}")

    for t in tables:
        do_full(t)
    print("\n[DONE] all dimension di bronze.")

def cmd_transactions(args):
    config.validate()
    meta = tcfg.TRANSACTION_TABLES.get(args.table)
    if not meta:
        raise SystemExit(f"[ERROR] {args.table} bukan tabel transaksi. Pilihan: {list(tcfg.TRANSACTION_TABLES)}")
    
    date_col = meta["date_col"]
    days = list(daterange(args.start, args.end))
    print(f"Backfill {args.table} ({date_col}) untuk {len(days)} hari: {args.start}..{args.end}")
    
    for day in days:
        print(f"\n--- {args.table} {day} ---")
        do_incremental_day(args.table, date_col, day)
    print(f"\n[DONE] Backfill {args.table} selesai.")

def main():
    p = argparse.ArgumentParser()
    sub = p.add_subparsers(dest="cmd", required=True)

    p_dim = sub.add_parser("dimensions", help="full-load semua tabel dimensi")
    p_dim.set_defaults(func=cmd_dimensions)

    p_tx = sub.add_parser("transactions", help="backfill tabel transaksi per rentang tanggal")
    p_tx.add_argument("--table", required=True)
    p_tx.add_argument("--start", required=True, help="YYYY-MM-DD inclusive")
    p_tx.add_argument("--end", required=True, help="YYYY-MM-DD exclusive")
    p_tx.set_defaults(func=cmd_transactions)

    args = p.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()