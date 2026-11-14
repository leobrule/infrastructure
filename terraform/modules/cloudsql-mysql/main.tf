locals {
  shared_core = contains(["db-f1-micro", "db-g1-small"], var.tier)
}

# --- Passwords (generated, stored in Secret Manager, never in Git) -------------

resource "random_password" "root" {
  length           = 24
  special          = true
  override_special = "-_=+.:"
}

resource "random_password" "admin" {
  length           = 24
  special          = true
  override_special = "-_=+.:"
}

# --- Instance ----------------------------------------------------------------------

resource "google_sql_database_instance" "this" {
  project          = var.project_id
  name             = var.name
  region           = var.region
  database_version = var.database_version
  root_password    = random_password.root.result

  deletion_protection = var.deletion_protection

  settings {
    edition           = var.edition
    tier              = var.tier
    availability_type = var.availability_type
    activation_policy = var.activation_policy
    pricing_plan      = "PER_USE"

    disk_type       = var.disk_type
    disk_size       = var.disk_size_gb
    disk_autoresize = var.disk_autoresize

    # GCP-side delete protection (separate from Terraform's deletion_protection).
    deletion_protection_enabled = var.deletion_protection

    connector_enforcement = var.connector_enforcement

    user_labels = var.labels

    ip_configuration {
      ipv4_enabled = true
      ssl_mode     = "ENCRYPTED_ONLY"

      dynamic "authorized_networks" {
        for_each = var.authorized_networks
        content {
          name  = authorized_networks.key
          value = authorized_networks.value
        }
      }
    }

    backup_configuration {
      enabled            = var.backup_enabled
      start_time         = var.backup_start_time
      binary_log_enabled = var.binary_log_enabled
      location           = var.region

      backup_retention_settings {
        retained_backups = var.retained_backups
        retention_unit   = "COUNT"
      }
    }

    maintenance_window {
      day          = var.maintenance_day
      hour         = var.maintenance_hour
      update_track = var.maintenance_update_track
    }

    insights_config {
      query_insights_enabled = var.query_insights_enabled
    }

    dynamic "database_flags" {
      for_each = var.database_flags
      content {
        name  = database_flags.key
        value = database_flags.value
      }
    }
  }

  lifecycle {
    precondition {
      condition     = !(local.shared_core && var.edition != "ENTERPRISE")
      error_message = "Shared-core tiers (db-f1-micro, db-g1-small) are only available in the ENTERPRISE edition."
    }
  }
}

# --- Databases and users ----------------------------------------------------------

resource "google_sql_database" "this" {
  for_each = toset(var.databases)

  project   = var.project_id
  instance  = google_sql_database_instance.this.name
  name      = each.value
  charset   = "utf8mb4"
  collation = "utf8mb4_0900_ai_ci"
}

resource "google_sql_user" "admin" {
  project  = var.project_id
  instance = google_sql_database_instance.this.name
  name     = var.admin_user
  host     = "%"
  password = random_password.admin.result
}

# --- Secret Manager ---------------------------------------------------------------

resource "google_secret_manager_secret" "root" {
  project   = var.project_id
  secret_id = "${var.name}-root-password"
  labels    = var.labels

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "root" {
  secret      = google_secret_manager_secret.root.id
  secret_data = random_password.root.result
}

resource "google_secret_manager_secret" "admin" {
  project   = var.project_id
  secret_id = "${var.name}-${var.admin_user}-password"
  labels    = var.labels

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "admin" {
  secret      = google_secret_manager_secret.admin.id
  secret_data = random_password.admin.result
}
