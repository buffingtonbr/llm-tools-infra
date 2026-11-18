# Microsoft Foundry (AIServices) resource for first-party Microsoft-format models
# (e.g., Microsoft-Decision-1.1). Separate from llm-tools-openai-bb because
# format = "Microsoft" deployments require kind = "AIServices" rather than "OpenAI".

resource "azurerm_cognitive_account" "foundry" {
  name                          = var.foundry_account_name
  resource_group_name           = azurerm_resource_group.llm.name
  location                      = azurerm_resource_group.llm.location
  kind                          = "AIServices"
  sku_name                      = "S0"
  custom_subdomain_name         = var.foundry_account_name
  local_auth_enabled            = false
  public_network_access_enabled = true

  identity {
    type = "SystemAssigned"
  }

  tags = azurerm_resource_group.llm.tags
}

resource "azurerm_cognitive_deployment" "microsoft_decision_1_1" {
  name                 = "decision-1-1"
  cognitive_account_id = azurerm_cognitive_account.foundry.id

  model {
    format  = "Microsoft"
    name    = "Microsoft-Decision-1.1"
    version = "1"
  }

  sku {
    name     = "GlobalStandard"
    capacity = 500
  }
}

resource "azurerm_role_assignment" "user_foundry_user" {
  scope                = azurerm_cognitive_account.foundry.id
  role_definition_name = "Cognitive Services User"
  principal_id         = local.current_user_oid
  principal_type       = "User"
}
