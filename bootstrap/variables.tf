variable "project_id" {
  description = "GCP project that holds the state bucket, the deploy service account and Cloud SQL."
  type        = string
}

variable "region" {
  description = "Default region."
  type        = string
  default     = "europe-west1"
}

variable "github_repository" {
  description = "owner/repo allowed to impersonate the deploy service account through WIF."
  type        = string
}

variable "state_bucket_name" {
  description = "Name of the GCS bucket for Terraform remote state."
  type        = string
}

variable "deployer_roles" {
  description = "Project roles for the deploy service account used by GitHub Actions."
  type        = list(string)
  # cloudsql.admin: create/modify Cloud SQL instances, databases and users.
  # secretmanager.admin: store the generated passwords in Secret Manager.
  default = [
    "roles/cloudsql.admin",
    "roles/secretmanager.admin",
  ]
}

variable "apis" {
  description = "APIs the project needs (already enabled by hand; listed here so the project is reproducible)."
  type        = list(string)
  default = [
    "sqladmin.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "sts.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "secretmanager.googleapis.com",
    "storage.googleapis.com",
  ]
}
