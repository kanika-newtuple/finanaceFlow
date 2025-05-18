# Storage Account for documents
resource "azurerm_storage_account" "storage" {
  name                     = "${var.prefix}${var.environment}storage"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  tags                     = var.tags
  public_network_access_enabled = true
}

# Container for unstructured documents
resource "azurerm_storage_container" "unstructured_docs" {
  name                  = var.container_name
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = var.container_access_type
}

# Enable diagnostic settings for Storage Account
resource "azurerm_monitor_diagnostic_setting" "storage_diag" {
  name                       = "${var.prefix}-${var.environment}-storage-diag"
  target_resource_id         = azurerm_storage_account.storage.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  metric {
    category = "Transaction"
    enabled  = true
    
  }

  metric {
    category = "Capacity"
    enabled  = true
    
  }
}

# Subnet for Storage Account private endpoint
resource "azurerm_subnet" "storage_subnet" {
  name                 = "storage-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.vnet.name
  address_prefixes     = [var.storage_subnet_address_prefix]

  # For Azure private endpoints we need to disable network policies
  private_endpoint_network_policies_enabled = true
}

# Private DNS Zone for Blob Storage
resource "azurerm_private_dns_zone" "blob_dns_zone" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Link the Private DNS Zone to the Virtual Network
resource "azurerm_private_dns_zone_virtual_network_link" "blob_dns_zone_link" {
  name                  = "blob-dns-zone-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.blob_dns_zone.name
  virtual_network_id    = var.vnet.id
  registration_enabled  = false
  tags                  = var.tags
}

# Create Private Endpoint for Storage Account
resource "azurerm_private_endpoint" "storage_endpoint" {
  name                = "${var.prefix}-${var.environment}-storage-endpoint"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.storage_subnet.id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.prefix}-${var.environment}-storage-connection"
    private_connection_resource_id = azurerm_storage_account.storage.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "blob-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob_dns_zone.id]
  }
}