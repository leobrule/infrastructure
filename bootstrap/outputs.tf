output "project_number" {
  value = data.google_project.this.number
}

output "state_bucket" {
  value = google_storage_bucket.tfstate.name
}

output "deployer_service_account" {
  description = "Set as the GitHub repository variable GCP_SA_EMAIL."
  value       = google_service_account.deployer.email
}

output "workload_identity_provider" {
  description = "Set as the GitHub repository variable GCP_WIF_PROVIDER."
  value       = google_iam_workload_identity_pool_provider.github.name
}
