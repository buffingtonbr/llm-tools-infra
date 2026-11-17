subscription_id           = "05e9015f-a93d-474b-8268-537f5e11f479"
tenant_id                 = "3086d9de-9316-49d0-a285-eefe8183cbec"
location                  = "eastus"
rg_name                   = "rg-llm-tools"
search_service_name       = "llm-tools-search"
storage_account_name      = "llmtoolsstor"
transcripts_container     = "transcripts"
openai_account_name       = "llm-tools-openai-bb"
alert_email               = "bbuffington@microsoft.com"
monthly_budget_amount     = 150
kv_rg_name                = "rg-llmtools-secrets"
kv_name                   = "kv-llmtools-personal"
kv_location               = "eastus2"
monitoring_rg_name        = "rg-monitoring"
monitoring_workspace_name = "law-monitoring-bbuf"

# Pin human owner Entra object ID explicitly so OIDC service-principal CI runs
# never replace owner data-plane RBAC assignments with the CI principal.
current_user_object_id = "5cc6afe4-6e97-4c43-9607-76bf5c8ace93"
