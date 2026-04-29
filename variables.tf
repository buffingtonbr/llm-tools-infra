variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
  default     = "05e9015f-a93d-474b-8268-537f5e11f479" # Visual Studio Enterprise
}

variable "tenant_id" {
  type        = string
  description = "Azure AD tenant ID"
  default     = "3086d9de-9316-49d0-a285-eefe8183cbec"
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "rg_name" {
  type    = string
  default = "rg-llm-tools"
}

variable "search_service_name" {
  type    = string
  default = "llm-tools-search"
}

variable "storage_account_name" {
  type    = string
  default = "llmtoolsstor"
}

variable "transcripts_container" {
  type    = string
  default = "transcripts"
}

variable "openai_account_name" {
  type        = string
  description = "Globally unique Cognitive Services account name."
  default     = "llm-tools-openai-bb"
}

variable "alert_email" {
  type        = string
  description = "Email for budget alerts."
  default     = "bbuffington@microsoft.com"
}

variable "monthly_budget_amount" {
  type    = number
  default = 150
}

variable "current_user_object_id" {
  type        = string
  description = "AAD object ID of the user running TF (gets data-plane RBAC). Empty = autodetect."
  default     = ""
}

variable "speech_account_name" {
  type        = string
  description = "Globally unique Azure AI Speech account name."
  default     = "llm-tools-speech-bb"
}
