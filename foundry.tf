# Microsoft Foundry (AIServices) resource for first-party Microsoft-format models
# (e.g., Microsoft-Decision-1.1). Separate from llm-tools-openai-bb because
# format = "Microsoft" deployments require kind = "AIServices" rather than "OpenAI".

resource "azurerm_cognitive_account" "foundry" {
  name                          = var.foundry_account_name
  resource_group_name           = azurerm_resource_group.llm.name
  location                      = azurerm_resource_group.llm.location
  kind                          = "AIServices"
  sku_name                      = "S0"
  custom_subdomain_name         = var.foundry_account_name
  local_auth_enabled            = false
  public_network_access_enabled = true

  identity {
    type = "SystemAssigned"
  }

  tags = azurerm_resource_group.llm.tags
}

resource "azurerm_cognitive_deployment" "microsoft_decision_1_1" {
  name                 = "decision-1-1"
  cognitive_account_id = azurerm_cognitive_account.foundry.id

  model {
    format  = "Microsoft"
    name    = "Microsoft-Decision-1.1"
    version = "1"
  }

  sku {
    name     = "GlobalStandard"
    capacity = 500
  }
}

resource "azurerm_role_assignment" "user_foundry_user" {
  scope                = azurerm_cognitive_account.foundry.id
  role_definition_name = "Cognitive Services User"
  principal_id         = local.current_user_oid
  principal_type       = "User"
}

# Keyless X.509 certificate workload identity for non-Azure SLAVE1 workers calling
# Microsoft-Decision-1.1. Key Vault generates the RSA key + certificate server-side,
# so only the public DER certificate enters Terraform state (zero secrets in state).
resource "azuread_application" "slave1_foundry_decision" {
  display_name            = "sp-slave1-foundry-decision-prd"
  description             = "X.509 workload identity for SLAVE1 containers calling Microsoft-Decision-1.1 on llm-tools-foundry-bb."
  owners                  = distinct(compact([local.current_user_oid, var.ci_service_principal_object_id]))
  prevent_duplicate_names = true
}

resource "azuread_service_principal" "slave1_foundry_decision" {
  client_id                    = azuread_application.slave1_foundry_decision.client_id
  app_role_assignment_required = false
  description                  = "Runtime service principal for SLAVE1 Microsoft-Decision-1.1 callers."
  owners                       = distinct(compact([local.current_user_oid, var.ci_service_principal_object_id]))
}

resource "azurerm_key_vault_certificate" "slave1_foundry_decision" {
  name         = "slave1-foundry-decision-cert"
  key_vault_id = azurerm_key_vault.personal.id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = false
    }

    lifetime_action {
      action {
        action_type = "AutoRenew"
      }

      trigger {
        days_before_expiry = 30
      }
    }

    secret_properties {
      content_type = "application/x-pem-file"
    }

    x509_certificate_properties {
      extended_key_usage = ["1.3.6.1.5.5.7.3.2"] # Client Authentication
      key_usage          = ["digitalSignature", "keyEncipherment"]
      subject            = "CN=sp-slave1-foundry-decision-prd"
      validity_in_months = 12
    }
  }

  tags = {
    Consumers        = "community-sources-ingest-worker,community-sources-triage-worker"
    ManagedBy        = "terraform"
    ManagementSource = "terraform"
    Owner            = "brian"
    RotationPolicy   = "AutoRenew-30d-before-expiry"
    Scope            = "personal-stack"
  }

  depends_on = [
    azurerm_role_assignment.kv_administrator,
    azurerm_role_assignment.ci_kv_certificates_officer,
    time_sleep.wait_ci_kv_cert_rbac,
  ]
}

resource "azuread_application_certificate" "slave1_foundry_decision" {
  application_id = azuread_application.slave1_foundry_decision.id
  type           = "AsymmetricX509Cert"
  encoding       = "hex"
  value          = azurerm_key_vault_certificate.slave1_foundry_decision.certificate_data
  end_date       = azurerm_key_vault_certificate.slave1_foundry_decision.certificate_attribute[0].expires
  start_date     = azurerm_key_vault_certificate.slave1_foundry_decision.certificate_attribute[0].not_before
}

resource "azurerm_role_assignment" "slave1_foundry_decision_user" {
  scope                = azurerm_cognitive_account.foundry.id
  role_definition_name = "Cognitive Services User"
  principal_id         = azuread_service_principal.slave1_foundry_decision.object_id
  principal_type       = "ServicePrincipal"
}
