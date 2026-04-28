# llm-tools-infra

Terraform for the LLM tools workload (`rg-llm-tools`). Single source of truth — replaces the per-repo TF in MSX_LLM and Copilot.

## Resources

Existing (imported from MSX_LLM's local state on first init):
- Resource group `rg-llm-tools`
- Azure AI Search (free) `llm-tools-search`
- Storage account `llmtoolsstor` + container `transcripts`
- Subscription budget `monthly-150` ($150/mo, 50/80/100 alerts)

Net-new (will be created on first apply):
- Azure OpenAI account `llm-tools-openai-bb` (S0)
  - Deployment `gpt-4-1-mini` (GlobalStandard, 50K TPM)
  - Deployment `text-embedding-3-small` (GlobalStandard, 50K TPM)
- Role grant: running user → `Cognitive Services OpenAI User` on the OpenAI account
- Role grant: running user → `Storage Blob Data Contributor` on the storage account

## Backend

Remote state in `tfstatebbuf01` / container `tfstate` / key `llm-tools.tfstate` (provisioned by https://github.com/buffingtonbr/llm-tools-bootstrap).

Auth: Entra ID via `az login`. No secrets.

## First-time setup

```powershell
# Make sure az is logged into the right subscription
az account set --subscription 05e9015f-a93d-474b-8268-537f5e11f479

# Init against the remote backend
terraform init

# Import the 5 existing resources from MSX_LLM into this state
$sub = "05e9015f-a93d-474b-8268-537f5e11f479"
terraform import azurerm_resource_group.llm "/subscriptions/$sub/resourceGroups/rg-llm-tools"
terraform import azurerm_search_service.search "/subscriptions/$sub/resourceGroups/rg-llm-tools/providers/Microsoft.Search/searchServices/llm-tools-search"
terraform import azurerm_storage_account.stor "/subscriptions/$sub/resourceGroups/rg-llm-tools/providers/Microsoft.Storage/storageAccounts/llmtoolsstor"
terraform import azurerm_storage_container.transcripts "https://llmtoolsstor.blob.core.windows.net/transcripts"
terraform import azurerm_consumption_budget_subscription.monthly "/subscriptions/$sub/providers/Microsoft.Consumption/budgets/monthly-150"

# Confirm the plan only shows OpenAI + role grants as net-new
terraform plan -out tfplan

# Apply
terraform apply tfplan
```

After this is done:
- Delete TF code from MSX_LLM (`infra/main.tf`, `infra/resources.tf`, `infra/variables.tf`, `infra/outputs.tf`, `infra/terraform.tfstate*`, `infra/.terraform/`, `infra/.terraform.lock.hcl`, `infra/terraform.tfvars`, `infra/tfplan`).
- Delete TF code from Copilot (`infra/terraform/`).
- Keep MSX_LLM's `infra/azure_costs.py` and indexer scripts — those consume Azure, they don't manage it.

## Day-2

Just `terraform plan` / `terraform apply` from this directory. State lives in Azure. No state files in git.
