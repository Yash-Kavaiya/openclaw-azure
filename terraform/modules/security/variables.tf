variable "prefix" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "tags" { type = map(string) }
variable "tenant_id" { type = string }
variable "object_id" { type = string }
variable "key_vault_sku" { type = string }
variable "secrets" { type = map(string); sensitive = true }
