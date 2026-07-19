variable "project_id" {
  description = "GCP Project ID (contoh: rental-pipeline-project)"
  type = string
}

variable "region" {
  description = "Region GCP untuk bucket & dataset"
  type = string
  default = "asia-southeast2" # Jakarta
}

variable "bucket_name" {
  description = "Nama bucket GCS untuk data lake"
  type = string
}

variable "datasets" {
  description = "Dataset BigQuery yang akan dibuat (medallion + CI)"
  type = list(string)
  default = ["bronze", "silver", "gold", "dbt_ci"]
}

variable "sa_account_id" {
  description = "Account ID untuk Service Account yang dikelola Terraform"
  type = string
  default = "airflow-sa-tf"
}
