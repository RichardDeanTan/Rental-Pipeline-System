output "bucket_name" {
  description = "Nama bucket GCS yang dibuat"
  value = google_storage_bucket.data_lake.name
}

output "bucket_url" {
  description = "URL gs:// bucket."
  value = "gs://${google_storage_bucket.data_lake.name}"
}

output "datasets_created" {
  description = "Daftar dataset BigQuery yang dibuat."
  value = [for d in google_bigquery_dataset.datasets : d.dataset_id]
}

output "service_account_email" {
  description = "Email Service Account yang dikelola Terraform (dipakai Airflow)."
  value = google_service_account.airflow_sa.email
}
