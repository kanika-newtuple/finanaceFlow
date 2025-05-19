# PostgreSQL Module

# Create a subnet for the PostgreSQL private endpoint
resource "azurerm_subnet" "postgres_subnet" {
  name                 = "postgres-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = [var.subnet_address_prefix]
  
  # Required for private endpoints
  private_endpoint_network_policies_enabled = true
  service_endpoints = ["Microsoft.Sql"]
}

# CosmosDB PostgreSQL Cluster
resource "azurerm_cosmosdb_postgresql_cluster" "postgres" {
  name                            = "${var.prefix}-${var.environment}-pg-cluster"
  resource_group_name             = var.resource_group_name
  location                        = var.location
  administrator_login_password    = var.postgres_admin_password
  coordinator_storage_quota_in_mb = var.storage_mb
  coordinator_vcore_count         = var.vcore_count
  node_count                      = var.node_count # Zero nodes means single coordinator mode
  sql_version                    = var.postgres_version

  tags = var.tags
}

# Enable diagnostic settings for PostgreSQL
resource "azurerm_monitor_diagnostic_setting" "postgres_diag" {
  name                       = "${var.prefix}-${var.environment}-pg-diag"
  target_resource_id         = azurerm_cosmosdb_postgresql_cluster.postgres.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "PostgreSQLLogs"
    
  }

  metric {
    category = "AllMetrics"
    

  }
}

# Private endpoint for PostgreSQL
resource "azurerm_private_endpoint" "postgres_endpoint" {
  name                = "${var.prefix}-${var.environment}-pg-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.postgres_subnet.id

  private_service_connection {
    name                           = "${var.prefix}-${var.environment}-pg-psc"
    private_connection_resource_id = azurerm_cosmosdb_postgresql_cluster.postgres.id
    is_manual_connection           = false
    subresource_names              = ["coordinator"]
  }

  tags = var.tags
}

# Create private DNS zone for PostgreSQL
resource "azurerm_private_dns_zone" "postgres_dns" {
  name                = "privatelink.cosmos.azure.com"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Link the private DNS zone with the virtual network
resource "azurerm_private_dns_zone_virtual_network_link" "postgres_dns_link" {
  name                  = "${var.prefix}-${var.environment}-pg-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.postgres_dns.name
  virtual_network_id    = var.virtual_network_id
  registration_enabled  = false
  tags                  = var.tags
}

# Create A record for the private endpoint
resource "azurerm_private_dns_a_record" "postgres_dns_record" {
  name                = azurerm_cosmosdb_postgresql_cluster.postgres.name
  zone_name           = azurerm_private_dns_zone.postgres_dns.name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.postgres_endpoint.private_service_connection[0].private_ip_address]
  tags                = var.tags
}

# Firewall rule to allow Azure services
resource "azurerm_cosmosdb_postgresql_firewall_rule" "allow_azure_services" {
  name             = "AllowAzureServices"
  cluster_id       = azurerm_cosmosdb_postgresql_cluster.postgres.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}
