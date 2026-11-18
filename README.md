# llm-tools-infra

Terraform for the LLM tools workload (`rg-llm-tools`). Single source of truth — replaces the per-repo TF in MSX_LLM and Copilot.

## Resources

Existing (imported from MSX_LLM's local state on first init):
- Resource group `rg-llm-tools`
- Azure AI Search (free) `llm-tools-search`
- Storage account `llmtoolsstor` + container `transcripts`
- Subscription budget `monthly-150` ($150/mo, 50/80/100 alerts)
- Personal Key Vault `kv-llmtools-personal` and its vault-scoped human-owner RBAC

Net-new (will be created on first apply):
- Azure OpenAI account `llm-tools-openai-bb` (S0)
  - Deployment `gpt-4-1-mini` (`gpt-4.1-mini` `2025-04-14`, GlobalStandard, 50K TPM)
  - Deployment `gpt-4-1` (`gpt-4.1` `2025-04-14`, Standard, 10K TPM — imported from prior CLI drift)
  - Deployment `gpt-5-1` (`gpt-5.1` `2025-11-13`, Standard, 10K TPM — imported from prior CLI drift)
  - Deployment `gpt-5-6-luna` (`gpt-5.6-luna` `2026-07-09`, GlobalStandard, 50K TPM)
  - Deployment `text-embedding-3-small` (GlobalStandard, 50K TPM)
- Microsoft Foundry (`AIServices`) account `llm-tools-foundry-bb` (S0, keyless Entra-only)
  - Deployment `microsoft-decision-1-1` (`Microsoft-Decision-1.1` `1`, GlobalStandard, 500 capacity)
- Role grant: human owner (`var.current_user_object_id`) → `Cognitive Services OpenAI User` on the OpenAI account
- Role grant: human owner (`var.current_user_object_id`) → `Cognitive Services User` on the Foundry account
- Role grant: human owner (`var.current_user_object_id`) → `Storage Blob Data Contributor` on the storage account
- Role grant: human owner (`var.current_user_object_id`) → `Key Vault Administrator` + `Key Vault Secrets Officer` on `kv-llmtools-personal`

The pre-existing `Key Vault Secrets Officer` assignment remains during the
Administrator rollout. Remove it only after key, certificate, and secret metadata
access is verified through the new role.

## Backend & Governed CD

- Remote state in `tfstatebbuf01` / container `tfstate` / nested per-config key `llm-tools/brb-llmtools-prd-eus.tfstate` (migrated from flat `llm-tools.tfstate` with a timestamped backup under `llm-tools/backups/2026-11-17-pre-cd-migration/llm-tools.tfstate`).
- Governed GitHub Actions workflows:
  - `.github/workflows/terraform-validate.yml` — fmt / init / validate / tflint / checkov + protected-environment alignment tests on every PR.
  - `.github/workflows/terraform-cd.yml` — manual `workflow_dispatch` on `main` only (`custom_branch_policies = true`, `main` only) calling `BRBuffington/terraform-pipelines-github/.github/workflows/terraform-cd.yml@main` with `pipelines_owner = "BRBuffington"`.
  - GitHub Environments: `personal` (plan, OIDC subject `repo:buffingtonbr/llm-tools-infra:environment:personal`) and `personal-apply` (apply, OIDC subject `repo:buffingtonbr/llm-tools-infra:environment:personal-apply`, gated by `confirm_action=APPLY`).

### Local read-only inspection

```powershell
terraform init -reconfigure '-backend-config=backend.hcl' '-backend-config=use_oidc=false' '-backend-config=use_cli=true'
terraform plan -lock=false '-var-file=environments/brb-llmtools-prd-eus.tfvars'
```

All infrastructure mutations go through reviewed PRs and `.github/workflows/terraform-cd.yml` — never a local `terraform apply` or ad-hoc `az` CLI mutation.
