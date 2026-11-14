variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "name" {
  description = "Instance name. Changing it replaces the instance (and a deleted name can't be reused for about a week)."
  type        = string
}

# --- Engine and size -----------------------------------------------------------

variable "database_version" {
  description = "MYSQL_8_4 is the current LTS. MYSQL_8_0 goes into paid extended support on 2027-01-01."
  type        = string
  default     = "MYSQL_8_4"
}

variable "edition" {
  description = "ENTERPRISE or ENTERPRISE_PLUS. Must be set explicitly: for MySQL 8.4 the API defaults to ENTERPRISE_PLUS."
  type        = string
  default     = "ENTERPRISE"

  validation {
    condition     = contains(["ENTERPRISE", "ENTERPRISE_PLUS"], var.edition)
    error_message = "edition must be ENTERPRISE or ENTERPRISE_PLUS."
  }
}

variable "tier" {
  description = "Machine type. db-f1-micro is the cheapest (shared core, 0.6 GB RAM, Enterprise edition only). Changing it restarts the instance."
  type        = string
  default     = "db-f1-micro"
}

variable "availability_type" {
  description = "ZONAL (single zone) or REGIONAL (HA, doubles the cost)."
  type        = string
  default     = "ZONAL"
}

variable "disk_type" {
  description = "PD_HDD (cheapest) or PD_SSD. Can't be changed later without recreating the instance."
  type        = string
  default     = "PD_HDD"
}

variable "disk_size_gb" {
  description = "Disk size in GB (minimum 10). It can grow later but never shrink."
  type        = number
  default     = 10
}

variable "disk_autoresize" {
  description = "Grow the disk automatically when it fills up. Off by default to keep costs fixed."
  type        = bool
  default     = false
}

variable "activation_policy" {
  description = "ALWAYS (running) or NEVER (stopped: no compute charge, storage and the IP are still billed)."
  type        = string
  default     = "ALWAYS"

  validation {
    condition     = contains(["ALWAYS", "NEVER"], var.activation_policy)
    error_message = "activation_policy must be ALWAYS or NEVER."
  }
}

# --- Protection ------------------------------------------------------------------

variable "deletion_protection" {
  description = "Terraform-side protection against destroy. false for training only."
  type        = bool
  default     = false
}

# --- Backups and maintenance ----------------------------------------------------

variable "backup_enabled" {
  type    = bool
  default = true
}

variable "backup_start_time" {
  description = "HH:MM, UTC."
  type        = string
  default     = "02:00"
}

variable "retained_backups" {
  type    = number
  default = 7
}

variable "binary_log_enabled" {
  description = "Needed for point-in-time recovery and replicas. Uses extra disk."
  type        = bool
  default     = false
}

variable "maintenance_day" {
  description = "1 = Monday ... 7 = Sunday."
  type        = number
  default     = 7
}

variable "maintenance_hour" {
  description = "0-23, UTC."
  type        = number
  default     = 3
}

variable "maintenance_update_track" {
  description = "canary, stable or week5."
  type        = string
  default     = "stable"
}

# --- Network and access ---------------------------------------------------------

variable "connector_enforcement" {
  description = "REQUIRED: only the Cloud SQL Auth Proxy / connectors can connect. NOT_REQUIRED also allows direct connections from authorized networks."
  type        = string
  default     = "REQUIRED"
}

variable "authorized_networks" {
  description = "CIDRs allowed to connect directly. Empty = Auth Proxy only."
  type        = map(string)
  default     = {}
}

# --- MySQL configuration --------------------------------------------------------

variable "database_flags" {
  description = "MySQL flags, e.g. { slow_query_log = \"on\" }. Some flags restart the instance."
  type        = map(string)
  default     = {}
}

variable "query_insights_enabled" {
  type    = bool
  default = false
}

variable "databases" {
  description = "Databases (schemas) to create."
  type        = list(string)
  default     = []
}

variable "admin_user" {
  description = "Name of the admin user created by Terraform. Its password goes to Secret Manager."
  type        = string
  default     = "dbadmin"
}

variable "labels" {
  type    = map(string)
  default = {}
}
