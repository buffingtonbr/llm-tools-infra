output "resource_group" {
  value = azurerm_resource_group.llm.name
}

output "search_endpoint" {
  value = "https://${azurerm_search_service.search.name}.search.windows.net"
}

output "blob_account_url" {
  value = azurerm_storage_account.stor.primary_blob_endpoint
}

output "transcripts_container" {
  value = azurerm_storage_container.transcripts.name
}

output "openai_endpoint" {
  value = azurerm_cognitive_account.openai.endpoint
}

output "openai_chat_deployment" {
  value = azurerm_cognitive_deployment.gpt_4_1_mini.name
}

output "openai_luna_deployment" {
  value = azurerm_cognitive_deployment.gpt_5_6_luna.name
}

output "openai_embed_deployment" {
  value = azurerm_cognitive_deployment.embedding_3_small.name
}

output "foundry_endpoint" {
  value = azurerm_cognitive_account.foundry.endpoint
}

output "foundry_decision_deployment" {
  value = azurerm_cognitive_deployment.microsoft_decision_1_1.name
}

output "foundry_sp_client_id" {
  value = azuread_application.slave1_foundry_decision.client_id
}

output "foundry_sp_cert_secret_name" {
  value = azurerm_key_vault_certificate.slave1_foundry_decision.name
}

output "keyvault_name" {
  value = azurerm_key_vault.personal.name
}

output "keyvault_uri" {
  value = azurerm_key_vault.personal.vault_uri
}
