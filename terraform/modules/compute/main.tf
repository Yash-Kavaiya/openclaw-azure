# ============================================================
# Compute Module - Azure VMs for Direct Hosting
# ============================================================

# ---- Public IPs for VMs ----
resource "azurerm_public_ip" "vm" {
  count               = var.vm_count
  name                = "${var.prefix}-vm-pip-${count.index}"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# ---- Network Interfaces ----
resource "azurerm_network_interface" "vm" {
  count               = var.vm_count
  name                = "${var.prefix}-vm-nic-${count.index}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm[count.index].id
  }
}

resource "azurerm_network_interface_security_group_association" "vm" {
  count                     = var.vm_count
  network_interface_id      = azurerm_network_interface.vm[count.index].id
  network_security_group_id = var.nsg_id
}

# ---- Cloud-Init / Custom Data ----
locals {
  cloud_init = templatefile("${path.module}/cloud-init.yaml.tpl", {
    acr_login_server      = var.acr_login_server
    acr_admin_username    = var.acr_admin_username
    acr_admin_password    = var.acr_admin_password
    database_url          = var.database_url
    redis_url             = var.redis_url
    key_vault_url         = var.key_vault_url
    app_insights_conn_str = var.app_insights_conn_str
    environment           = var.environment
  })
}

# ---- Virtual Machines ----
resource "azurerm_linux_virtual_machine" "vm" {
  count               = var.vm_count
  name                = "${var.prefix}-vm-${count.index}"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm_size
  admin_username      = var.vm_admin_username
  tags                = var.tags

  custom_data = base64encode(local.cloud_init)

  network_interface_ids = [
    azurerm_network_interface.vm[count.index].id,
  ]

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    name                 = "${var.prefix}-vm-osdisk-${count.index}"
    caching              = "ReadWrite"
    storage_account_type = var.vm_disk_type
    disk_size_gb         = var.vm_disk_size_gb
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }

  boot_diagnostics {}
}

# ---- VM Extensions ----

# Azure Monitor Agent
resource "azurerm_virtual_machine_extension" "monitor_agent" {
  count                      = var.vm_count
  name                       = "AzureMonitorLinuxAgent"
  virtual_machine_id         = azurerm_linux_virtual_machine.vm[count.index].id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.29"
  auto_upgrade_minor_version = true
  tags                       = var.tags
}

# ---- Managed Disks for data ----
resource "azurerm_managed_disk" "data" {
  count                = var.vm_count
  name                 = "${var.prefix}-vm-datadisk-${count.index}"
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = var.vm_disk_type
  create_option        = "Empty"
  disk_size_gb         = 32
  tags                 = var.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "data" {
  count              = var.vm_count
  managed_disk_id    = azurerm_managed_disk.data[count.index].id
  virtual_machine_id = azurerm_linux_virtual_machine.vm[count.index].id
  lun                = 0
  caching            = "ReadOnly"
}
