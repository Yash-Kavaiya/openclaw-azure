# ============================================================
# OpenClaw - Terraform Variables
# ============================================================

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "East US 2"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "openclaw"
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}

# ---- Networking ----
variable "vnet_address_space" {
  description = "Virtual network address space"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_app_prefix" {
  description = "App subnet CIDR"
  type        = string
  default     = "10.0.1.0/24"
}

variable "subnet_db_prefix" {
  description = "Database subnet CIDR"
  type        = string
  default     = "10.0.2.0/24"
}

variable "subnet_bastion_prefix" {
  description = "Azure Bastion subnet CIDR (must be /26 or larger)"
  type        = string
  default     = "10.0.3.0/26"
}

variable "subnet_agw_prefix" {
  description = "Application Gateway subnet CIDR"
  type        = string
  default     = "10.0.4.0/24"
}

# ---- Virtual Machine ----
variable "vm_size" {
  description = "Azure VM size"
  type        = string
  default     = "Standard_B2s"
}

variable "vm_disk_size_gb" {
  description = "OS disk size in GB"
  type        = number
  default     = 64
}

variable "vm_disk_type" {
  description = "Managed disk type (Standard_LRS, StandardSSD_LRS, Premium_LRS)"
  type        = string
  default     = "StandardSSD_LRS"
}

variable "vm_admin_username" {
  description = "VM administrator username"
  type        = string
  default     = "azureuser"
}

variable "vm_count" {
  description = "Number of application VM instances"
  type        = number
  default     = 1
}

variable "enable_bastion" {
  description = "Enable Azure Bastion for secure VM access"
  type        = bool
  default     = true
}

# ---- Database ----
variable "postgres_sku" {
  description = "PostgreSQL Flexible Server SKU"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "postgres_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "16"
}

variable "postgres_storage_mb" {
  description = "PostgreSQL storage in MB"
  type        = number
  default     = 32768
}

variable "postgres_admin_user" {
  description = "PostgreSQL administrator username"
  type        = string
  default     = "openclaw_admin"
  sensitive   = true
}

variable "postgres_admin_password" {
  description = "PostgreSQL administrator password"
  type        = string
  sensitive   = true
}

variable "postgres_db_name" {
  description = "Initial database name"
  type        = string
  default     = "openclaw"
}

# ---- Redis ----
variable "redis_capacity" {
  description = "Redis Cache capacity"
  type        = number
  default     = 1
}

variable "redis_family" {
  description = "Redis Cache family (C=Basic/Standard, P=Premium)"
  type        = string
  default     = "C"
}

variable "redis_sku" {
  description = "Redis Cache SKU (Basic, Standard, Premium)"
  type        = string
  default     = "Standard"
}

# ---- Application Gateway / Load Balancer ----
variable "enable_application_gateway" {
  description = "Deploy Azure Application Gateway"
  type        = bool
  default     = false
}

# ---- Container Registry ----
variable "acr_sku" {
  description = "Azure Container Registry SKU (Basic, Standard, Premium)"
  type        = string
  default     = "Standard"
}

# ---- Key Vault ----
variable "key_vault_sku" {
  description = "Key Vault SKU (standard or premium)"
  type        = string
  default     = "standard"
}

# ---- Monitoring ----
variable "log_retention_days" {
  description = "Log Analytics workspace retention days"
  type        = number
  default     = 30
}

# ---- Alerts ----
variable "alert_email" {
  description = "Email address for Azure Monitor alerts"
  type        = string
  default     = ""
}

# ---- SSH ----
variable "ssh_public_key_path" {
  description = "Path to SSH public key for VM access (ignored if ssh_public_key is set)"
  type        = string
  default     = ""
}

variable "ssh_public_key" {
  description = "SSH public key content (if provided, overrides ssh_public_key_path). Leave empty to auto-generate."
  type        = string
  default     = ""
}

variable "allowed_ssh_ips" {
  description = "IP CIDRs allowed for SSH access (empty = use Bastion only)"
  type        = list(string)
  default     = []
}
