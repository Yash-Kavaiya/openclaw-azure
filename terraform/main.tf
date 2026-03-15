# ============================================================
# OpenClaw - Main Terraform Configuration
# Azure Direct-Host Deployment
# ============================================================

locals {
  prefix = "${var.project_name}-${var.environment}"
  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Repository  = "openclaw-azure"
  })
}

# ---- Resource Group ----
resource "azurerm_resource_group" "main" {
  name     = "${local.prefix}-rg"
  location = var.location
  tags     = local.common_tags
}

# ---- Networking Module ----
module "networking" {
  source = "./modules/networking"

  prefix                = local.prefix
  resource_group_name   = azurerm_resource_group.main.name
  location              = var.location
  tags                  = local.common_tags
  vnet_address_space    = var.vnet_address_space
  subnet_app_prefix     = var.subnet_app_prefix
  subnet_db_prefix      = var.subnet_db_prefix
  subnet_bastion_prefix = var.subnet_bastion_prefix
  subnet_agw_prefix     = var.subnet_agw_prefix
  allowed_ssh_ips       = var.allowed_ssh_ips
  enable_bastion        = var.enable_bastion
}

# ---- Security Module (Key Vault) ----
module "security" {
  source = "./modules/security"

  prefix              = local.prefix
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  tags                = local.common_tags
  tenant_id           = data.azurerm_client_config.current.tenant_id
  object_id           = data.azurerm_client_config.current.object_id
  key_vault_sku       = var.key_vault_sku

  secrets = {
    postgres-admin-password = var.postgres_admin_password
    jwt-secret-key          = random_password.jwt_secret.result
    app-secret-key          = random_password.app_secret.result
  }
}

# ---- Database Module ----
module "database" {
  source = "./modules/database"

  prefix                  = local.prefix
  resource_group_name     = azurerm_resource_group.main.name
  location                = var.location
  tags                    = local.common_tags
  subnet_id               = module.networking.subnet_db_id
  private_dns_zone_id     = module.networking.postgres_private_dns_zone_id
  postgres_sku            = var.postgres_sku
  postgres_version        = var.postgres_version
  postgres_storage_mb     = var.postgres_storage_mb
  postgres_admin_user     = var.postgres_admin_user
  postgres_admin_password = var.postgres_admin_password
  postgres_db_name        = var.postgres_db_name
  redis_capacity          = var.redis_capacity
  redis_family            = var.redis_family
  redis_sku               = var.redis_sku
}

# ---- Compute Module ----
module "compute" {
  source = "./modules/compute"

  prefix                = local.prefix
  resource_group_name   = azurerm_resource_group.main.name
  location              = var.location
  tags                  = local.common_tags
  subnet_id             = module.networking.subnet_app_id
  nsg_id                = module.networking.nsg_app_id
  vm_size               = var.vm_size
  vm_disk_size_gb       = var.vm_disk_size_gb
  vm_disk_type          = var.vm_disk_type
  vm_admin_username     = var.vm_admin_username
  vm_count              = var.vm_count
  ssh_public_key        = file(var.ssh_public_key_path)
  acr_login_server      = azurerm_container_registry.acr.login_server
  acr_admin_username    = azurerm_container_registry.acr.admin_username
  acr_admin_password    = azurerm_container_registry.acr.admin_password
  database_url          = "postgresql+asyncpg://${var.postgres_admin_user}:${var.postgres_admin_password}@${module.database.postgres_fqdn}:5432/${var.postgres_db_name}"
  redis_url             = "rediss://:${module.database.redis_primary_key}@${module.database.redis_hostname}:6380/0"
  key_vault_url         = module.security.key_vault_uri
  app_insights_conn_str = azurerm_application_insights.main.connection_string
  environment           = var.environment
}

# ---- Azure Container Registry ----
resource "azurerm_container_registry" "acr" {
  name                = replace("${local.prefix}acr", "-", "")
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  sku                 = var.acr_sku
  admin_enabled       = true
  tags                = local.common_tags

  identity {
    type = "SystemAssigned"
  }
}

# ---- Azure Storage Account ----
resource "azurerm_storage_account" "main" {
  name                     = replace("${local.prefix}sa", "-", "")
  resource_group_name      = azurerm_resource_group.main.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = var.environment == "prod" ? "GRS" : "LRS"
  min_tls_version          = "TLS1_2"
  https_traffic_only_enabled = true
  tags                     = local.common_tags

  blob_properties {
    versioning_enabled  = true
    delete_retention_policy {
      days = 7
    }
  }
}

resource "azurerm_storage_container" "app" {
  name                  = "openclaw"
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"
}

# ---- Log Analytics Workspace ----
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${local.prefix}-law"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = local.common_tags
}

# ---- Application Insights ----
resource "azurerm_application_insights" "main" {
  name                = "${local.prefix}-ai"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"
  tags                = local.common_tags
}

# ---- Monitor Action Group (Alerts) ----
resource "azurerm_monitor_action_group" "main" {
  count               = var.alert_email != "" ? 1 : 0
  name                = "${local.prefix}-ag"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "openclaw"
  tags                = local.common_tags

  email_receiver {
    name          = "admin"
    email_address = var.alert_email
  }
}

# ---- CPU Alert ----
resource "azurerm_monitor_metric_alert" "cpu" {
  count               = length(module.compute.vm_ids)
  name                = "${local.prefix}-cpu-alert-${count.index}"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [module.compute.vm_ids[count.index]]
  description         = "Alert when VM CPU exceeds 80%"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"
  tags                = local.common_tags

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  dynamic "action" {
    for_each = azurerm_monitor_action_group.main
    content {
      action_group_id = action.value.id
    }
  }
}

# ---- Random secrets ----
resource "random_password" "jwt_secret" {
  length  = 64
  special = true
}

resource "random_password" "app_secret" {
  length  = 64
  special = true
}
