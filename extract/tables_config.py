TRANSACTION_TABLES = {
    "rental":  {"mode": "incremental", "date_col": "rental_date"},
    "payment": {"mode": "incremental", "date_col": "payment_date"},
}

DIMENSION_TABLES = {
    "customer":      {"mode": "full"},
    "film":          {"mode": "full"},
    "staff":         {"mode": "full"},
    "store":         {"mode": "full"},
    "address":       {"mode": "full"},
    "city":          {"mode": "full"},
    "country":       {"mode": "full"},
    "category":      {"mode": "full"},
    "language":      {"mode": "full"},
    "actor":         {"mode": "full"},
    "film_actor":    {"mode": "full"},
    "film_category": {"mode": "full"},
    "inventory":     {"mode": "full"},
    "exchange_rate": {"mode": "full"},
}

ALL_TABLES = {**TRANSACTION_TABLES, **DIMENSION_TABLES}