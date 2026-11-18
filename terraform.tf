terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.20"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  subscription_id = var.subscription_id

  features {
    cognitive_account {
      purge_soft_delete_on_destroy = true
    }
    key_vault {
      purge_soft_deleted_certificates_on_destroy = true
      recover_soft_deleted_certificates          = true
    }
  }
}

provider "azuread" {
  tenant_id = var.tenant_id
}

data "azurerm_subscription" "current" {}
data "azurerm_client_config" "current" {}

locals {
  current_user_oid = var.current_user_object_id != "" ? var.current_user_object_id : data.azurerm_client_config.current.object_id
}
