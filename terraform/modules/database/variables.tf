variable "prefix" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "tags" { type = map(string) }
variable "subnet_id" { type = string }
variable "private_dns_zone_id" { type = string }
variable "postgres_sku" { type = string }
variable "postgres_version" { type = string }
variable "postgres_storage_mb" { type = number }
variable "postgres_admin_user" { type = string; sensitive = true }
variable "postgres_admin_password" { type = string; sensitive = true }
variable "postgres_db_name" { type = string }
variable "redis_capacity" { type = number }
variable "redis_family" { type = string }
variable "redis_sku" { type = string }
