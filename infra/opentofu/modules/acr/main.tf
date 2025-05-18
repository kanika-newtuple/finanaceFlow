# Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = "${var.prefix}${var.environment}acr"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = var.admin_enabled
  tags                = var.tags

  # Add network rule settings for private access
  public_network_access_enabled = var.public_network_access_enabled
  network_rule_bypass_option    = "AzureServices"
}

# Enable diagnostic settings for ACR
resource "azurerm_monitor_diagnostic_setting" "acr_diag" {
  name                       = "${var.prefix}-${var.environment}-acr-diag"
  target_resource_id         = azurerm_container_registry.acr.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  
  enabled_log {
    category = "ContainerRegistryRepositoryEvents"
  }
  
  enabled_log {
    category = "ContainerRegistryLoginEvents"
  }
  
  metric {
    category = "AllMetrics"
  }
}

# Push a dummy image to the registry
resource "null_resource" "push_dummy_image" {
  depends_on = [azurerm_container_registry.acr]

  triggers = {
    acr_id = azurerm_container_registry.acr.id
    # Force re-run on every apply by using timestamp as a trigger
    timestamp = timestamp()
  }

  provisioner "local-exec" {
    command     = <<EOT
      set -e
      echo "Logging into ACR..."
      az acr login --name ${azurerm_container_registry.acr.name} || { echo "Failed to login to ACR"; exit 1; }
      echo "Pulling hello-world image..."
      docker pull --platform=linux/amd64 hello-world || { echo "Failed to pull hello-world image"; exit 1; }
      echo "Tagging image..."
      docker tag hello-world:latest ${azurerm_container_registry.acr.login_server}/dummyimage:${var.dummy_image_tag} || { echo "Failed to tag image"; exit 1; }
      echo "Pushing image to ACR..."
      docker push ${azurerm_container_registry.acr.login_server}/dummyimage:${var.dummy_image_tag} || { echo "Failed to push image to ACR"; exit 1; }
      echo "Image pushed successfully to ACR"
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
}

# Private DNS Zone for ACR
resource "azurerm_private_dns_zone" "acr_dns" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "privatelink.azurecr.io"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Link the Private DNS Zone to the VNet
resource "azurerm_private_dns_zone_virtual_network_link" "acr_dns_link" {
  count                 = var.enable_private_endpoint ? 1 : 0
  name                  = "${var.prefix}-${var.environment}-acr-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.acr_dns[0].name
  virtual_network_id    = var.virtual_network_id
  registration_enabled  = false
  tags                  = var.tags
}

# Private Endpoint for ACR
resource "azurerm_private_endpoint" "acr_endpoint" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "${var.prefix}-${var.environment}-acr-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "${var.prefix}-${var.environment}-acr-connection"
    private_connection_resource_id = azurerm_container_registry.acr.id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }

  private_dns_zone_group {
    name                 = "${var.prefix}-${var.environment}-acr-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.acr_dns[0].id]
  }

  tags = var.tags
}

# # Grant AKS kubelet identity access to ACR
# resource "azurerm_role_assignment" "aks_acr_pull" {
#   depends_on = [ azurerm_container_registry.acr ]
#   # count                = var.aks_kubelet_identity_object_id != "" ? 1 : 0
#   principal_id         = var.aks_kubelet_identity_object_id
#   role_definition_name = "AcrPull"
#   scope                = azurerm_container_registry.acr.id
#   skip_service_principal_aad_check = true
# }
