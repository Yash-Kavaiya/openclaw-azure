# ============================================================
# OpenClaw - Dev Environment Variables
# Lightweight: VM + ACR + SQLite (no PostgreSQL/Redis)
# ============================================================

environment  = "dev"
location     = "Central India"
project_name = "openclaw"

# Feature flags
enable_database = false  # Use SQLite — no PostgreSQL/Redis cost
enable_bastion  = false  # Save cost in dev

# Networking
vnet_address_space    = ["10.0.0.0/16"]
subnet_app_prefix     = "10.0.1.0/24"
subnet_db_prefix      = "10.0.2.0/24"
subnet_bastion_prefix = "10.0.3.0/26"
subnet_agw_prefix     = "10.0.4.0/24"

# VM
vm_size           = "Standard_B2s"
vm_disk_size_gb   = 64
vm_disk_type      = "StandardSSD_LRS"
vm_admin_username = "azureuser"
vm_count          = 1

# Container Registry
acr_sku = "Basic"

# Key Vault
key_vault_sku = "standard"

# Monitoring
log_retention_days = 30

# SSH
allowed_ssh_ips = []

tags = {
  CostCenter = "dev"
  Owner      = "yash-kavaiya"
}
