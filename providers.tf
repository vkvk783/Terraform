terraform {
  # Terraform version and provider requirements
  required_version = ">= 1.6.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }

  # Configure the remote backend to store the Terraform state in Azure Storage
  backend "azurerm" {
    resource_group_name  = "rg-taskmanager-tfstate"
    storage_account_name = "sttaskmanagertfstate"
    container_name       = "tfstate"
    key                  = "taskmanager.tfstate"
  }

}

# Configure the Azure provider with specific features and settings for key vault and resource group management
# prevention of accidental deletion. This ensures that soft-deleted key vaults can be recovered and that resource groups cannot be deleted if they contain resources, adding an extra layer of safety to the infrastructure management.
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }

    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}