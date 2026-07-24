# Personal Key Vault for cross-device LLM tool secrets.
# Imported 2026-05-13 — RG + KV + RBAC role were created via az CLI before
# being adopted into Terraform.

variable "kv_rg_name" {
  type    = string
  default = "rg-llmtools-secrets"
}

variable "kv_name" {
  type        = string
  description = "Globally unique Key Vault name."
  default     = "kv-llmtools-personal"
}

variable "kv_location" {
  type    = string
  default = "eastus2"
}

resource "azurerm_resource_group" "secrets" {
  name     = var.kv_rg_name
  location = var.kv_location

  tags = {
    project = "llm-tools"
    purpose = "secrets"
    owner   = "brian"
    managed = "terraform"
  }
}

resource "azurerm_key_vault" "personal" {
  name                = var.kv_name
  resource_group_name = azurerm_resource_group.secrets.name
  location            = azurerm_resource_group.secrets.location
  tenant_id           = var.tenant_id
  sku_name            = "standard"

  enable_rbac_authorization     = true # azurerm v5 will rename to rbac_authorization_enabled
  purge_protection_enabled      = true
  soft_delete_retention_days    = 90
  public_network_access_enabled = true

  tags = azurerm_resource_group.secrets.tags
}

# Preserve the existing secret CRUD grant until administrator access is live-verified.
resource "azurerm_role_assignment" "kv_secrets_officer" {
  scope                = azurerm_key_vault.personal.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = local.current_user_oid
  principal_type       = "User"
}

resource "azurerm_role_assignment" "kv_administrator" {
  scope                = azurerm_key_vault.personal.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = local.current_user_oid
  principal_type       = "User"
  description          = "Human owner administration for the personal Key Vault data plane."
}
