terraform {
  required_version = ">= 1.14.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.8"
    }
  }

  # Bootstrap starts with LOCAL state (the bucket doesn't exist yet).
  # After the first apply you can move this state into the bucket it created:
  #   1. Uncomment the block below
  #   2. terraform init -migrate-state
  #
  # backend "gcs" {
  #   bucket = "mysqlproject-501213-tfstate"
  #   prefix = "bootstrap"
  # }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
