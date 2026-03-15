variable "prefix" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "tags" { type = map(string) }
variable "subnet_id" { type = string }
variable "nsg_id" { type = string }
variable "vm_size" { type = string }
variable "vm_disk_size_gb" { type = number }
variable "vm_disk_type" { type = string }
variable "vm_admin_username" { type = string }
variable "vm_count" { type = number }
variable "ssh_public_key" { type = string }
variable "acr_login_server" { type = string }
variable "acr_admin_username" { type = string }
variable "acr_admin_password" { type = string; sensitive = true }
variable "database_url" { type = string; sensitive = true }
variable "redis_url" { type = string; sensitive = true }
variable "key_vault_url" { type = string }
variable "app_insights_conn_str" { type = string; sensitive = true }
variable "environment" { type = string }
