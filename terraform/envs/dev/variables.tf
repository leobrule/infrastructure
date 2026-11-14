variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "environment" {
  type = string
}

variable "mysql" {
  description = "Cloud SQL MySQL settings. Change them in dev.tfvars through a pull request."
  type = object({
    name                     = string
    database_version         = optional(string, "MYSQL_8_4")
    edition                  = optional(string, "ENTERPRISE")
    tier                     = optional(string, "db-f1-micro")
    availability_type        = optional(string, "ZONAL")
    disk_type                = optional(string, "PD_HDD")
    disk_size_gb             = optional(number, 10)
    disk_autoresize          = optional(bool, false)
    activation_policy        = optional(string, "ALWAYS")
    deletion_protection      = optional(bool, false)
    backup_enabled           = optional(bool, true)
    backup_start_time        = optional(string, "02:00")
    retained_backups         = optional(number, 7)
    binary_log_enabled       = optional(bool, false)
    maintenance_day          = optional(number, 7)
    maintenance_hour         = optional(number, 3)
    maintenance_update_track = optional(string, "stable")
    query_insights_enabled   = optional(bool, false)
    database_flags           = optional(map(string), {})
    databases                = optional(list(string), [])
    admin_user               = optional(string, "dbadmin")
  })
}
