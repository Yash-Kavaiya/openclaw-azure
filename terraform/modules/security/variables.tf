variable "prefix" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "tags" { type = map(string) }
variable "tenant_id" { type = string }
variable "object_id" { type = string }
variable "key_vault_sku" { type = string }

variable "secrets" {
  description = "Map of secret names to values to store in Key Vault. Keys are not sensitive (used in for_each)."
  type        = map(string)
}
