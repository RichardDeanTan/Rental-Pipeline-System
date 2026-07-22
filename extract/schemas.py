from google.cloud import bigquery

SF = bigquery.SchemaField

SCHEMAS = {
    "rental": [
        SF("rental_id",        "INTEGER"),
        SF("rental_date",      "TIMESTAMP"),
        SF("inventory_id",     "INTEGER"),
        SF("customer_id",      "INTEGER"),
        SF("return_date",      "TIMESTAMP"),
        SF("staff_id",         "INTEGER"),
        SF("last_update",      "TIMESTAMP"),
    ],
    "payment": [
        SF("payment_id",        "INTEGER"),
        SF("customer_id",       "INTEGER"),
        SF("staff_id",          "INTEGER"),
        SF("rental_id",         "INTEGER"),
        SF("amount",            "FLOAT64"),
        SF("payment_date",      "TIMESTAMP"),
    ],
}
