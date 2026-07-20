"""
Contoh:
  python extract/extract_fx_api.py --start 2026-07-14 --end 2026-07-15
"""

import argparse
import requests
import pandas as pd

import config

BASE_URL = "https://api.frankfurter.app"


def fetch_fx(start, end):
    url = f"{BASE_URL}/{start}..{end}?from=USD&to=IDR"
    print(f"[FX] GET {url}")
    resp = requests.get(url, timeout=30)
    resp.raise_for_status()
    payload = resp.json()

    rates = payload.get("rates", {})
    rows = []
    for date_str, obj in sorted(rates.items()):
        if "IDR" in obj:
            rows.append({
                "rate_date": date_str,
                "currency": "IDR",
                "rate": obj["IDR"],
            })
    df = pd.DataFrame(rows)
    print(f"[FX] {len(df)} baris kurs terambil")
    return df


def upload_parquet(df, start):
    if df.empty:
        print("[SKIP] no data.")
        return None
    uri = f"gs://{config.GCS_BUCKET}/raw/fx/dt={start}/data.parquet"
    df.to_parquet(uri, index=False, engine="pyarrow")
    print(f"[UPLOAD] {len(df)} baris → {uri}")
    return uri


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--start", required=True, help="YYYY-MM-DD (inclusive)")
    p.add_argument("--end", required=True, help="YYYY-MM-DD (exclusive)")
    args = p.parse_args()

    config.validate()
    df = fetch_fx(args.start, args.end)
    upload_parquet(df, args.start)


if __name__ == "__main__":
    main()
