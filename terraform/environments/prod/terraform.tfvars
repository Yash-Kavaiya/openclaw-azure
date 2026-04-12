# ============================================================
# OpenClaw - Prod Environment Variables
# ============================================================

environment  = "prod"
location     = "Central India"
project_name = "openclaw"

# Networking
vnet_address_space    = ["10.0.0.0/16"]
subnet_app_prefix     = "10.0.1.0/24"
subnet_db_prefix      = "10.0.2.0/24"
subnet_bastion_prefix = "10.0.3.0/26"
subnet_agw_prefix     = "10.0.4.0/24"

# VM - Prod uses larger instances
vm_size           = "Standard_D2s_v3"
vm_disk_size_gb   = 128
vm_disk_type      = "Premium_LRS"
vm_admin_username = "azureuser"
vm_count          = 2
enable_bastion    = true

# Database - Prod uses general purpose tier
postgres_sku        = "GP_Standard_D2s_v3"
postgres_version    = "16"
postgres_storage_mb = 65536
postgres_admin_user = "openclaw_admin"
postgres_db_name    = "openclaw"

# Redis - Prod uses Standard
redis_capacity = 1
redis_family   = "C"
redis_sku      = "Standard"

# Container Registry
acr_sku = "Standard"

# Key Vault
key_vault_sku = "standard"

# Monitoring
log_retention_days = 90

# SSH
allowed_ssh_ips = []

# Alerts
alert_email = ""

# SSH Key path
ssh_public_key_path = "~/.ssh/id_rsa.pub"

tags = {
  CostCenter = "production"
  Owner      = "yash-kavaiya"
}
