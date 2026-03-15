output "vm_ids" {
  value = azurerm_linux_virtual_machine.vm[*].id
}

output "vm_public_ips" {
  value = azurerm_public_ip.vm[*].ip_address
}

output "vm_private_ips" {
  value = azurerm_network_interface.vm[*].private_ip_address
}

output "vm_names" {
  value = azurerm_linux_virtual_machine.vm[*].name
}

output "vm_identities" {
  value = azurerm_linux_virtual_machine.vm[*].identity[0].principal_id
}
