# Azure AI Speech — used by dnd-voice-bot for real-time per-speaker transcription
# of Discord D&D sessions. Standard tier (S0) so we get diarization, custom phrase
# lists, and unlimited concurrent recognizers. Billed against MSDN credits.

resource "azurerm_cognitive_account" "speech" {
  name                  = var.speech_account_name
  resource_group_name   = azurerm_resource_group.llm.name
  location              = azurerm_resource_group.llm.location
  kind                  = "SpeechServices"
  sku_name              = "S0"
  custom_subdomain_name = var.speech_account_name # required for Entra ID auth
  local_auth_enabled    = true                    # bot uses subscription key (simpler than token-server pattern)

  tags = azurerm_resource_group.llm.tags
}

# Data-plane access for the running user (Entra ID auth, no keys).
# Bot itself uses the account key from key vault / env, but the user needs
# this role to read keys + manage the resource.
resource "azurerm_role_assignment" "user_speech_user" {
  scope                = azurerm_cognitive_account.speech.id
  role_definition_name = "Cognitive Services Speech User"
  principal_id         = local.current_user_oid
}

resource "azurerm_role_assignment" "user_speech_contributor" {
  scope                = azurerm_cognitive_account.speech.id
  role_definition_name = "Cognitive Services Contributor"
  principal_id         = local.current_user_oid
}
