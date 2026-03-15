# ============================================================
# Database Module - PostgreSQL Flexible Server + Redis Cache
# ============================================================

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# ---- PostgreSQL Flexible Server ----
resource "azurerm_postgresql_flexible_server" "main" {
  name                          = "${var.prefix}-pg-${random_string.suffix.result}"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  version                       = var.postgres_version
  delegated_subnet_id           = var.subnet_id
  private_dns_zone_id           = var.private_dns_zone_id
  public_network_access_enabled = false
  administrator_login           = var.postgres_admin_user
  administrator_password        = var.postgres_admin_password
  zone                          = "1"
  tags                          = var.tags

  storage_mb            = var.postgres_storage_mb
  storage_tier          = "P4"

  sku_name = var.postgres_sku

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  maintenance_window {
    day_of_week  = 0
    start_hour   = 2
    start_minute = 0
  }

  lifecycle {
    ignore_changes = [zone]
  }
}

# ---- PostgreSQL Database ----
resource "azurerm_postgresql_flexible_server_database" "app" {
  name      = var.postgres_db_name
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

# ---- PostgreSQL Configuration ----
resource "azurerm_postgresql_flexible_server_configuration" "max_connections" {
  name      = "max_connections"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = "100"
}

resource "azurerm_postgresql_flexible_server_configuration" "work_mem" {
  name      = "work_mem"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = "4096"
}

# ---- Azure Cache for Redis ----
resource "azurerm_redis_cache" "main" {
  name                = "${var.prefix}-redis-${random_string.suffix.result}"
  resource_group_name = var.resource_group_name
  location            = var.location
  capacity            = var.redis_capacity
  family              = var.redis_family
  sku_name            = var.redis_sku
  non_ssl_port_enabled = false
  minimum_tls_version = "1.2"
  tags                = var.tags

  redis_configuration {
    maxmemory_reserved              = 50
    maxmemory_delta                 = 50
    maxmemory_policy                = "allkeys-lru"
    maxfragmentationmemory_reserved = 50
  }
}
