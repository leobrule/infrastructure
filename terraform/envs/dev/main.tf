# mysql_enabled = false removes the instance (and its data); true creates it.
module "mysql" {
  source = "../../modules/cloudsql-mysql"
  count  = var.mysql_enabled ? 1 : 0

  project_id = var.project_id
  region     = var.region
  name       = var.mysql.name

  database_version         = var.mysql.database_version
  edition                  = var.mysql.edition
  tier                     = var.mysql.tier
  availability_type        = var.mysql.availability_type
  disk_type                = var.mysql.disk_type
  disk_size_gb             = var.mysql.disk_size_gb
  disk_autoresize          = var.mysql.disk_autoresize
  activation_policy        = var.mysql.activation_policy
  deletion_protection      = var.mysql.deletion_protection
  backup_enabled           = var.mysql.backup_enabled
  backup_start_time        = var.mysql.backup_start_time
  retained_backups         = var.mysql.retained_backups
  binary_log_enabled       = var.mysql.binary_log_enabled
  maintenance_day          = var.mysql.maintenance_day
  maintenance_hour         = var.mysql.maintenance_hour
  maintenance_update_track = var.mysql.maintenance_update_track
  query_insights_enabled   = var.mysql.query_insights_enabled
  database_flags           = var.mysql.database_flags
  databases                = var.mysql.databases
  admin_user               = var.mysql.admin_user

  labels = {
    env        = var.environment
    managed_by = "terraform"
    repo       = "infrastructure"
  }
}

# The module used to have no count. Keeps an existing instance in place
# (no destroy and recreate) when this change is applied to a running one.
moved {
  from = module.mysql
  to   = module.mysql[0]
}
