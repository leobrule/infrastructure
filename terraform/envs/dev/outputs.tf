# Outputs are null while mysql_enabled = false.
output "mysql_instance_name" {
  value = one(module.mysql[*].instance_name)
}

output "mysql_connection_name" {
  value = one(module.mysql[*].connection_name)
}

output "mysql_public_ip" {
  value = one(module.mysql[*].public_ip)
}

output "mysql_admin_user" {
  value = one(module.mysql[*].admin_user)
}

output "mysql_admin_password_secret" {
  value = one(module.mysql[*].admin_password_secret)
}

output "mysql_root_password_secret" {
  value = one(module.mysql[*].root_password_secret)
}
