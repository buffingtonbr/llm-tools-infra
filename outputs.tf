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

output "openai_embed_deployment" {
  value = azurerm_cognitive_deployment.embedding_3_small.name
}

output "speech_endpoint" {
  value = azurerm_cognitive_account.speech.endpoint
}

output "speech_region" {
  value = azurerm_cognitive_account.speech.location
}

output "speech_account_name" {
  value = azurerm_cognitive_account.speech.name
}

output "speech_key" {
  value     = azurerm_cognitive_account.speech.primary_access_key
  sensitive = true
}
