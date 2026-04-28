# Existing resources — imported from MSX_LLM's local state.
# DO NOT change names; that would force destroy/recreate.

resource "azurerm_resource_group" "llm" {
  name     = var.rg_name
  location = var.location

  tags = {
    project = "llm-tools"
    managed = "terraform"
  }
}

resource "azurerm_search_service" "search" {
  name                = var.search_service_name
  resource_group_name = azurerm_resource_group.llm.name
  location            = azurerm_resource_group.llm.location
  sku                 = "free"
  replica_count       = 1
  partition_count     = 1

  tags = azurerm_resource_group.llm.tags
}

resource "azurerm_storage_account" "stor" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.llm.name
  location                 = azurerm_resource_group.llm.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  min_tls_version          = "TLS1_2"

  tags = azurerm_resource_group.llm.tags
}

resource "azurerm_storage_container" "transcripts" {
  name                  = var.transcripts_container
  storage_account_id    = azurerm_storage_account.stor.id
  container_access_type = "private"
}

# Subscription budget — alerts at 50/80/100% of monthly_budget_amount
resource "azurerm_consumption_budget_subscription" "monthly" {
  name            = "monthly-150"
  subscription_id = data.azurerm_subscription.current.id
  amount          = var.monthly_budget_amount
  time_grain      = "Monthly"

  time_period {
    start_date = "2026-05-01T00:00:00Z"
  }

  notification {
    enabled        = true
    threshold      = 50
    operator       = "GreaterThan"
    contact_emails = [var.alert_email]
  }

  notification {
    enabled        = true
    threshold      = 80
    operator       = "GreaterThan"
    contact_emails = [var.alert_email]
  }

  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThan"
    contact_emails = [var.alert_email]
  }
}
