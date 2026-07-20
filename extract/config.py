import os
from dotenv import load_dotenv

load_dotenv()

# GCP
GCP_PROJECT_ID = os.getenv("GCP_PROJECT_ID")
GCS_BUCKET = os.getenv("GCS_BUCKET")
BQ_LOCATION = os.getenv("BQ_LOCATION", "asia-southeast2")

# Postgres
PG_HOST = os.getenv("PG_HOST", "localhost")
PG_PORT = os.getenv("PG_PORT", "5432")
PG_DB = os.getenv("PG_DB", "rentaldb")
PG_USER = os.getenv("PG_USER", "postgres")
PG_PASSWORD = os.getenv("PG_PASSWORD", "postgres")


def pg_conn_string():
    """SQLAlchemy connection Postgres."""
    return f"postgresql+psycopg2://{PG_USER}:{PG_PASSWORD}@{PG_HOST}:{PG_PORT}/{PG_DB}"


def validate():
    missing = [k for k in ["GCP_PROJECT_ID", "GCS_BUCKET"] if not globals()[k]]
    if missing:
        raise SystemExit(f"[CONFIG ERROR] Env empty.")
    cred = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
    if not cred or not os.path.exists(cred):
        raise SystemExit(f"[CONFIG ERROR] GOOGLE_APPLICATION_CREDENTIALS not found.")