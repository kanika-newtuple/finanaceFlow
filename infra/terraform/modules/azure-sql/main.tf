# SQL Server Subnet
resource "azurerm_subnet" "sql_subnet" {
  name                 = "sql-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = [var.subnet_address_prefix]
  
  # For SQL private endpoint 
  private_endpoint_network_policies_enabled = true
  service_endpoints = ["Microsoft.Sql"]
}

# Azure SQL Server
resource "azurerm_mssql_server" "sql_server" {
  name                         = "${var.prefix}-${var.environment}-sqlserver"
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password
  minimum_tls_version          = "1.2"
  public_network_access_enabled = var.public_network_access_enabled
  tags = var.tags
}

# Azure SQL Database
resource "azurerm_mssql_database" "sql_database" {
  name                 = "${var.prefix}_${var.environment}_db"
  server_id            = azurerm_mssql_server.sql_server.id
  sku_name             = var.sql_database_sku
  collation            = "SQL_Latin1_General_CP1_CI_AS"
  max_size_gb          = var.max_size_gb
  storage_account_type = "Local"

  tags = var.tags
}

# Enable diagnostic settings for SQL Database
resource "azurerm_monitor_diagnostic_setting" "sql_db_diag" {
  name                       = "${var.prefix}-${var.environment}-sqldb-diag"
  target_resource_id         = azurerm_mssql_database.sql_database.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  
  enabled_log {
    category = "SQLInsights"
  }
  
  enabled_log {
    category = "AutomaticTuning"
  }
  
  enabled_log {
    category = "QueryStoreRuntimeStatistics"
  }
  
  enabled_log {
    category = "Errors"
  }
  
  enabled_log {
    category = "DatabaseWaitStatistics"
  }
  
  enabled_log {
    category = "Timeouts"
  }
  
  enabled_log {
    category = "Blocks"
  }
  
  metric {
    category = "AllMetrics"
  }
}

# Firewall rule to allow Azure services if public network access is enabled
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  count            = var.public_network_access_enabled ? 1 : 0
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.sql_server.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Private DNS Zone for SQL Server
resource "azurerm_private_dns_zone" "sql_dns_zone" {
  name                = "privatelink.database.windows.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Link the DNS Zone to the Virtual Network
resource "azurerm_private_dns_zone_virtual_network_link" "sql_dns_zone_link" {
  name                  = "${var.prefix}-${var.environment}-sql-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.sql_dns_zone.name
  virtual_network_id    = var.virtual_network_id
  tags                  = var.tags
}

# Create Private Endpoint for SQL Server
resource "azurerm_private_endpoint" "sql_private_endpoint" {
  name                = "${var.prefix}-${var.environment}-sql-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.sql_subnet.id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.prefix}-${var.environment}-sql-psc"
    private_connection_resource_id = azurerm_mssql_server.sql_server.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.sql_dns_zone.id]
  }
}
