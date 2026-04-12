# ============================================================
# OpenClaw - Terraform Outputs
# ============================================================

output "resource_group_name" {
  description = "Resource Group name"
  value       = azurerm_resource_group.main.name
}

output "vm_public_ips" {
  description = "Public IP addresses of application VMs"
  value       = module.compute.vm_public_ips
}

output "vm_private_ips" {
  description = "Private IP addresses of application VMs"
  value       = module.compute.vm_private_ips
}

output "vm_ids" {
  description = "VM resource IDs"
  value       = module.compute.vm_ids
}

output "postgres_fqdn" {
  description = "PostgreSQL Flexible Server FQDN"
  value       = var.enable_database ? module.database[0].postgres_fqdn : "N/A (SQLite mode)"
}

output "redis_hostname" {
  description = "Redis Cache hostname"
  value       = var.enable_database ? module.database[0].redis_hostname : "N/A (disabled)"
}

output "acr_login_server" {
  description = "Azure Container Registry login server"
  value       = azurerm_container_registry.acr.login_server
}

output "acr_name" {
  description = "Azure Container Registry name"
  value       = azurerm_container_registry.acr.name
}

output "storage_account_name" {
  description = "Storage account name"
  value       = azurerm_storage_account.main.name
}

output "storage_connection_string" {
  description = "Storage account connection string"
  value       = azurerm_storage_account.main.primary_connection_string
  sensitive   = true
}

output "key_vault_uri" {
  description = "Key Vault URI"
  value       = module.security.key_vault_uri
}

output "key_vault_name" {
  description = "Key Vault name"
  value       = module.security.key_vault_name
}

output "application_insights_instrumentation_key" {
  description = "Application Insights Instrumentation Key"
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Application Insights Connection String"
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}

output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  value       = azurerm_log_analytics_workspace.main.workspace_id
}

output "vnet_id" {
  description = "Virtual Network ID"
  value       = module.networking.vnet_id
}

output "app_url" {
  description = "Application URL (first VM public IP)"
  value       = length(module.compute.vm_public_ips) > 0 ? "http://${module.compute.vm_public_ips[0]}" : "N/A"
}

output "ssh_command" {
  description = "SSH command to connect to first VM"
  value       = length(module.compute.vm_public_ips) > 0 ? "ssh ${var.vm_admin_username}@${module.compute.vm_public_ips[0]}" : "Use Azure Bastion"
}

output "ssh_private_key" {
  description = "Generated SSH private key (save to Key Vault or download securely)"
  value       = tls_private_key.ssh.private_key_pem
  sensitive   = true
}

output "database_mode" {
  description = "Database mode in use"
  value       = var.enable_database ? "PostgreSQL + Redis (Azure managed)" : "SQLite (embedded)"
}
