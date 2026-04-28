terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.20"
    }
  }

  backend "azurerm" {
    use_azuread_auth     = true
    use_cli              = true
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstatebbuf01"
    container_name       = "tfstate"
    key                  = "llm-tools.tfstate"
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id

  features {
    cognitive_account {
      purge_soft_delete_on_destroy = true
    }
  }
}

data "azurerm_subscription" "current" {}
data "azurerm_client_config" "current" {}

locals {
  current_user_oid = var.current_user_object_id != "" ? var.current_user_object_id : data.azurerm_client_config.current.object_id
}
