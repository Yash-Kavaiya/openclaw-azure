output "vnet_id" { value = azurerm_virtual_network.vnet.id }
output "vnet_name" { value = azurerm_virtual_network.vnet.name }
output "subnet_app_id" { value = azurerm_subnet.app.id }
output "subnet_db_id" { value = azurerm_subnet.db.id }
output "nsg_app_id" { value = azurerm_network_security_group.app.id }
output "postgres_private_dns_zone_id" { value = azurerm_private_dns_zone.postgres.id }
