terraform {
  required_version = ">= 1.5"
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region = var.region
}

# Bucket GCS (data lake)
resource "google_storage_bucket" "data_lake" {
  name = var.bucket_name
  location = var.region
  force_destroy = true

  # IAM sama
  uniform_bucket_level_access = true

  # hapus file lebih dari 90 hari
  lifecycle_rule {
    condition {
      age = 90
      matches_prefix = ["raw/"]
    }
    action {
      type = "Delete"
    }
  }
}

# BigQuery (bronze, silver, gold, dbt_ci)
resource "google_bigquery_dataset" "datasets" {
  for_each = toset(var.datasets)
  dataset_id = each.value
  location = var.region

  # saat `terraform destroy` --> hapus juga tabel di dalamnya.
  delete_contents_on_destroy = true
}

# Service Account Airflow
resource "google_service_account" "airflow_sa" {
  account_id = var.sa_account_id
  display_name = "Airflow SA (managed by Terraform)"
}

# IAM role untuk SA Airflow
locals {
  sa_roles = [
    "roles/storage.admin",
    "roles/bigquery.dataEditor",
    "roles/bigquery.jobUser",
  ]
}

resource "google_project_iam_member" "airflow_sa_roles" {
  for_each = toset(local.sa_roles)
  project = var.project_id
  role = each.value
  member = "serviceAccount:${google_service_account.airflow_sa.email}"
}
