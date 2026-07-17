import time
import argparse
import pandas as pd
import requests
import psycopg2
from psycopg2.extras import execute_values


class CurrencyFetcher:
    def __init__(self, start_date, end_date, base_currency, target_currency):
        self.start_date = start_date
        self.end_date = end_date
        self.base_currency = base_currency
        self.target_currency = target_currency
        self.base_url = "https://api.frankfurter.app"
        self.data = []

    def fetch_monthly_rates(self):
        date_range = pd.date_range(start=self.start_date, end=self.end_date, freq="MS")

        for dt in date_range:
            date_str = dt.strftime("%Y-%m-%d")
            url = f"{self.base_url}/{date_str}?from={self.base_currency}&to={self.target_currency}"

            response = requests.get(url, timeout=30)
            result = response.json()

            if "rates" in result and self.target_currency in result["rates"]:
                rate = result["rates"][self.target_currency]
                actual_date = result.get("date", date_str)
                self.data.append({
                    "rate_date": date_str,
                    "actual_rate_date": actual_date,
                    "currency": self.target_currency,
                    "rate": rate,
                })
                print(f"[SUCCESS] {date_str} (ECB {actual_date}) | 1 {self.base_currency} = {rate} {self.target_currency}")
            else:
                print(f"[WARNING] Data tidak ditemukan untuk {date_str}.")

            time.sleep(0.1)

    def to_dataframe(self):
        if not self.data:
            return pd.DataFrame(columns=["rate_date", "actual_rate_date", "currency", "rate"])
        return pd.DataFrame(self.data)


def export_to_csv(df, filename):
    if df.empty:
        print("[INFO] Tidak ada data untuk diekspor ke CSV.")
        return
    df.to_csv(filename, index=False)
    print(f"[INFO] CSV tersimpan: {filename} ({len(df)} baris)")


def load_to_postgres(df, conn_params):
    if df.empty:
        print("[INFO] Tidak ada data untuk dimuat ke Postgres.")
        return

    rows = [
        (r.rate_date, r.currency, r.rate)
        for r in df.itertuples(index=False)
    ]

    sql = """
        INSERT INTO exchange_rate (rate_date, currency, rate)
        VALUES %s
        ON CONFLICT (rate_date) DO UPDATE
            SET currency = EXCLUDED.currency,
                rate     = EXCLUDED.rate;
    """

    conn = psycopg2.connect(**conn_params)
    try:
        with conn.cursor() as cur:
            execute_values(cur, sql, rows)
        conn.commit()
    finally:
        conn.close()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--start", default="2005-01-01")
    parser.add_argument("--end", default="2026-07-01")
    parser.add_argument("--csv", default="postgres/data/exchange_rate.csv")
    parser.add_argument("--host", default="localhost")
    parser.add_argument("--port", default="5432")
    parser.add_argument("--dbname", default="rentaldb")
    parser.add_argument("--user", default="postgres")
    parser.add_argument("--password", default="postgres")
    parser.add_argument("--skip-db", action="store_true",
                        help="Hanya tarik API + simpan CSV, jangan insert ke Postgres")
    args = parser.parse_args()

    fetcher = CurrencyFetcher(
        start_date=args.start,
        end_date=args.end,
        base_currency="USD",
        target_currency="IDR",
    )
    fetcher.fetch_monthly_rates()
    df = fetcher.to_dataframe()

    export_to_csv(df, args.csv)

    if not args.skip_db:
        conn_params = {
            "host": args.host,
            "port": args.port,
            "dbname": args.dbname,
            "user": args.user,
            "password": args.password,
        }
        load_to_postgres(df, conn_params)

if __name__ == "__main__":
    main()

# python postgres/scripts/seed_exchange_rate.py --start 2005-01-01 --end 2026-07-01