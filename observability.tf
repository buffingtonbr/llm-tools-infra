# Key Vault audit logging.
#
# Why this exists: on 2026-07-27 a credential-exposure investigation needed to
# answer "which secrets are actually read?" so unused entries could be retired
# without guessing. The vault had no diagnostic settings, so there was no read
# history at all — the same blind spot as `log_connections=off` on pg-llmtools.
# Retirement decisions were therefore being made from repo greps, which only
# cover one repo and cannot see SLAVE1 container env or the other infra repos.
#
# AuditEvent records every data-plane secret read with caller identity, which
# turns "no grep hits" into "not read in N days" — evidence instead of
# inference. It is also the control that would have made the 2.5-month
# `PG_LLMTOOLS_CREDS_JSON` exposure detectable rather than merely present.
#
# Destination is the shared workspace owned by BRBuffington/monitoring-infra.
# It is referenced as a data source, never managed here.

variable "monitoring_rg_name" {
  type        = string
  description = "Resource group holding the shared Log Analytics workspace."
  default     = "rg-monitoring"
}

variable "monitoring_workspace_name" {
  type        = string
  description = "Shared Log Analytics workspace that receives Key Vault audit logs."
  default     = "law-monitoring-bbuf"
}

data "azurerm_log_analytics_workspace" "monitoring" {
  name                = var.monitoring_workspace_name
  resource_group_name = var.monitoring_rg_name
}

resource "azurerm_monitor_diagnostic_setting" "kv_audit" {
  name                       = "diag-${var.kv_name}-audit"
  target_resource_id         = azurerm_key_vault.personal.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.monitoring.id

  # AuditEvent is the load-bearing category: one row per data-plane secret
  # get/set, with caller identity. AzurePolicyEvaluationDetails is cheap and
  # completes the vault's log surface.
  enabled_log {
    category = "AuditEvent"
  }

  enabled_log {
    category = "AzurePolicyEvaluationDetails"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
