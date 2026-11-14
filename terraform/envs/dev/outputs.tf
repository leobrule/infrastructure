output "mysql_instance_name" {
  value = module.mysql.instance_name
}

output "mysql_connection_name" {
  value = module.mysql.connection_name
}

output "mysql_public_ip" {
  value = module.mysql.public_ip
}

output "mysql_admin_user" {
  value = module.mysql.admin_user
}

output "mysql_admin_password_secret" {
  value = module.mysql.admin_password_secret
}

output "mysql_root_password_secret" {
  value = module.mysql.root_password_secret
}
