terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # Remote state in Azure Storage (uncomment after bootstrapping)
  # backend "azurerm" {
  #   resource_group_name  = "openclaw-tfstate-rg"
  #   storage_account_name = "openclawtfstate"
  #   container_name       = "tfstate"
  #   key                  = "openclaw.terraform.tfstate"
  # }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
    virtual_machine {
      delete_os_disk_on_deletion     = true
      graceful_shutdown              = false
      skip_shutdown_and_force_delete = false
    }
  }
  subscription_id = var.subscription_id
}

provider "azuread" {}

provider "random" {}

provider "tls" {}

# Data sources
data "azurerm_client_config" "current" {}
