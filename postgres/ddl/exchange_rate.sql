CREATE TABLE IF NOT EXISTS exchange_rate (
    rate_date   DATE PRIMARY KEY,
    currency    VARCHAR(3) NOT NULL,
    rate        NUMERIC(12,4) NOT NULL,
    loaded_at   TIMESTAMP DEFAULT NOW()
);