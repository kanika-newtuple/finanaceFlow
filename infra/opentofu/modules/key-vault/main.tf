resource "azurerm_key_vault" "key_vault" {
  name                      = "${var.prefix}-${var.environment}-kv"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = var.tenant_id
  enabled_for_disk_encryption = true
  soft_delete_retention_days = var.soft_delete_retention_days
  purge_protection_enabled   = var.purge_protection_enabled
  sku_name                   = var.sku_name
  enable_rbac_authorization  = var.enable_rbac_authorization
  tags                       = var.tags
}

resource "azurerm_monitor_diagnostic_setting" "key_vault_diag" {
  name                       = "${var.prefix}-${var.environment}-diag"
  target_resource_id         = azurerm_key_vault.key_vault.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AuditEvent"
  }

  enabled_log {
    category = "AzurePolicyEvaluationDetails"
  }

  metric {
    category = "AllMetrics"
  }
}

resource "azurerm_role_assignment" "admin" {
  scope                = azurerm_key_vault.key_vault.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = var.admin_principal_id
}