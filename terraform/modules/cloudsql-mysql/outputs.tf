output "instance_name" {
  value = google_sql_database_instance.this.name
}

output "connection_name" {
  description = "project:region:instance — what the Cloud SQL Auth Proxy (and later Ansible) connects to."
  value       = google_sql_database_instance.this.connection_name
}

output "public_ip" {
  value = google_sql_database_instance.this.public_ip_address
}

output "admin_user" {
  value = google_sql_user.admin.name
}

output "admin_password_secret" {
  value = google_secret_manager_secret.admin.secret_id
}

output "root_password_secret" {
  value = google_secret_manager_secret.root.secret_id
}

output "databases" {
  value = [for db in google_sql_database.this : db.name]
}
