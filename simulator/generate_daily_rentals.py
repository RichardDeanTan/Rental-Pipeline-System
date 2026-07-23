"""
Contoh:
  python simulator/generate_daily_rentals.py
  python simulator/generate_daily_rentals.py --n 5
  python simulator/generate_daily_rentals.py --date 2026-07-20
  python simulator/generate_daily_rentals.py --force
"""

import os
import argparse
import random
from datetime import datetime, date, timedelta

import psycopg2
from dotenv import load_dotenv

load_dotenv()

PG = {
    "host":     os.getenv("PG_HOST", "localhost"),
    "port":     os.getenv("PG_PORT", "5432"),
    "dbname":   os.getenv("PG_DB", "rentaldb"),
    "user":     os.getenv("PG_USER", "postgres"),
    "password": os.getenv("PG_PASSWORD", "postgres"),
}


def fetch_reference_ids(cur):
    """Ambil pool id yang sudah ada untuk dipakai sebagai FK."""
    cur.execute("SELECT customer_id FROM customer")
    customers = [r[0] for r in cur.fetchall()]
    cur.execute("SELECT film_id FROM film")
    films = [r[0] for r in cur.fetchall()]
    cur.execute("SELECT staff_id FROM staff")
    staff = [r[0] for r in cur.fetchall()]
    # inventory diperlukan karena rental menunjuk inventory_id (bukan film langsung)
    cur.execute("SELECT inventory_id, store_id FROM inventory")
    inventory = cur.fetchall()  # list of (inventory_id, store_id)
    return customers, films, staff, inventory


def already_simulated(cur, target_date):
    """Cek apakah sudah ada rental bertanggal target_date (penanda simulasi)."""
    cur.execute(
        "SELECT COUNT(*) FROM rental WHERE rental_date::date = %s",
        (target_date,),
    )
    return cur.fetchone()[0] > 0


def simulate(cur, target_date, n):
    customers, films, staff, inventory = fetch_reference_ids(cur)

    if not inventory:
        raise SystemExit("[ERROR] tabel inventory kosong; tidak bisa membuat rental.")

    inserted_rentals = 0
    inserted_payments = 0

    for _ in range(n):
        inv_id, store_id = random.choice(inventory)
        cust_id = random.choice(customers)
        staff_id = random.choice(staff)

        # jam acak dalam hari target, biar terlihat natural
        rental_ts = datetime.combine(target_date, datetime.min.time()) + timedelta(
            hours=random.randint(8, 22), minutes=random.randint(0, 59)
        )

        # 1) INSERT rental — biarkan sequence isi rental_id, RETURNING utk dapat id-nya
        cur.execute(
            """
            INSERT INTO rental (rental_date, inventory_id, customer_id, staff_id, last_update)
            VALUES (%s, %s, %s, %s, NOW())
            RETURNING rental_id
            """,
            (rental_ts, inv_id, cust_id, staff_id),
        )
        rental_id = cur.fetchone()[0]
        inserted_rentals += 1

        # 2) INSERT payment yang menunjuk rental_id di atas (FK-safe)
        amount = round(random.uniform(0.99, 9.99), 2)
        payment_ts = rental_ts + timedelta(minutes=random.randint(1, 30))
        cur.execute(
            """
            INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)
            VALUES (%s, %s, %s, %s, %s)
            """,
            (cust_id, staff_id, rental_id, amount, payment_ts),
        )
        inserted_payments += 1

    return inserted_rentals, inserted_payments


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--date", help="tanggal target YYYY-MM-DD (default: hari ini)")
    p.add_argument("--n", type=int, default=10, help="jumlah rental+payment (default 10)")
    p.add_argument("--force", action="store_true", help="abaikan idempotency, tetap insert")
    args = p.parse_args()

    target_date = (
        datetime.strptime(args.date, "%Y-%m-%d").date() if args.date else date.today()
    )

    conn = psycopg2.connect(**PG)
    try:
        with conn.cursor() as cur:
            if not args.force and already_simulated(cur, target_date):
                print(f"[SKIP] sudah ada data untuk {target_date}. "
                      f"Pakai --force untuk menimpa/menambah.")
                return
            r, pmt = simulate(cur, target_date, args.n)
        conn.commit()
        print(f"[OK] {target_date}: +{r} rental, +{pmt} payment ke Postgres.")
    finally:
        conn.close()


if __name__ == "__main__":
    main()
