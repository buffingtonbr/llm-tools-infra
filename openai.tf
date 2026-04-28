# Net-new in this migration: Azure OpenAI for digests / embeddings.

resource "azurerm_cognitive_account" "openai" {
  name                  = var.openai_account_name
  resource_group_name   = azurerm_resource_group.llm.name
  location              = azurerm_resource_group.llm.location
  kind                  = "OpenAI"
  sku_name              = "S0"
  custom_subdomain_name = var.openai_account_name # required for Entra ID auth
  local_auth_enabled    = true                    # keep keys available as fallback

  tags = azurerm_resource_group.llm.tags
}

resource "azurerm_cognitive_deployment" "gpt_4_1_mini" {
  name                 = "gpt-4-1-mini"
  cognitive_account_id = azurerm_cognitive_account.openai.id

  model {
    format  = "OpenAI"
    name    = "gpt-4.1-mini"
    version = "2025-04-14"
  }

  sku {
    name     = "GlobalStandard"
    capacity = 50
  }
}

resource "azurerm_cognitive_deployment" "embedding_3_small" {
  name                 = "text-embedding-3-small"
  cognitive_account_id = azurerm_cognitive_account.openai.id

  model {
    format  = "OpenAI"
    name    = "text-embedding-3-small"
    version = "1"
  }

  sku {
    name     = "GlobalStandard"
    capacity = 50
  }
}

# Data-plane access for the running user (Entra ID auth, no keys).
resource "azurerm_role_assignment" "user_openai_user" {
  scope                = azurerm_cognitive_account.openai.id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = local.current_user_oid
}

# Storage Blob Data Contributor for the running user (used by transcript indexer).
resource "azurerm_role_assignment" "user_blob_contributor" {
  scope                = azurerm_storage_account.stor.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = local.current_user_oid
}
