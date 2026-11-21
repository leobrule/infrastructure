terraform {
  required_version = ">= 1.14.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.8"
    }
  }

  # Bootstrap was first applied with LOCAL state (the bucket didn't exist yet).
  # Its state now lives in the bucket it created, under its own prefix.
  # Apply bootstrap only from a laptop or VM with your own gcloud login,
  # never from the pipeline.
  backend "gcs" {
    bucket = "mysqlproject-501213-tfstate"
    prefix = "bootstrap"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
