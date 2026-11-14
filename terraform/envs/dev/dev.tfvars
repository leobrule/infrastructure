# Settings for the dev environment.
# To change the database: edit this file on a branch, open a PR, read the plan
# comment, merge, then approve the "dev" environment to apply.
#
# Changes that RESTART the instance: tier, most database_flags, activation_policy.
# Changes that REPLACE the instance (data lost): name, disk_type, region, edition downgrade paths.

project_id  = "mysqlproject-501213"
region      = "europe-west1"
environment = "dev"

mysql = {
  name             = "mysql-dev"
  database_version = "MYSQL_8_4"
  edition          = "ENTERPRISE"

  # Cheapest possible: shared-core, zonal, 10 GB HDD, no autoresize.
  tier              = "db-f1-micro"
  availability_type = "ZONAL"
  disk_type         = "PD_HDD"
  disk_size_gb      = 10
  disk_autoresize   = false

  # Set to "NEVER" to stop the instance when you're not using it.
  activation_policy = "ALWAYS"

  deletion_protection = false # training only

  backup_enabled     = true
  backup_start_time  = "02:00" # UTC
  retained_backups   = 7
  binary_log_enabled = false

  maintenance_day          = 7 # Sunday
  maintenance_hour         = 3 # UTC
  maintenance_update_track = "stable"

  query_insights_enabled = false

  database_flags = {}

  databases  = ["training"]
  admin_user = "dbadmin"
}
