resource "azurerm_subnet" "container_env_subnet" {
  name                 = "${var.prefix}-${var.environment}-container-env-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = [var.subnet_address_prefix]

  # Required delegations for Container App Environment
  delegation {
    name = "Microsoft.App.environments"
    service_delegation {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# New subnet specifically for private endpoints
resource "azurerm_subnet" "private_endpoint_subnet" {
  name                 = "${var.prefix}-${var.environment}-pe-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = [var.pe_subnet_address_prefix]
  
  # Disable private endpoint network policies
  private_endpoint_network_policies_enabled = false
}

resource "azurerm_container_app_environment" "container_env" {
  name                       = "${var.prefix}-${var.environment}-env"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  log_analytics_workspace_id = var.log_analytics_workspace_id
  infrastructure_subnet_id   = azurerm_subnet.container_env_subnet.id
  
  # Enable internal networking for private access
  internal_load_balancer_enabled = true
  
  dynamic "workload_profile" {
    for_each = var.workload_profiles
    content {
      name                  = workload_profile.value.name
      workload_profile_type = workload_profile.value.workload_profile_type
      minimum_count         = lookup(workload_profile.value, "minimum_count", 1)
      maximum_count         = lookup(workload_profile.value, "maximum_count", 2)
    }
  }
  lifecycle {
    ignore_changes = [
      log_analytics_workspace_id
    ]
  }

  tags = var.tags
}

# Enable diagnostic settings for Container App Environment
resource "azurerm_monitor_diagnostic_setting" "container_env_diag" {
  name                       = "${var.prefix}-${var.environment}-container-env-diag"
  target_resource_id         = azurerm_container_app_environment.container_env.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "ContainerAppConsoleLogs"
    
  }

  enabled_log {
    category = "ContainerAppSystemLogs"
    
  }

  metric {
    category = "AllMetrics"
    
  }
}

# Private DNS Zone for Container Apps
resource "azurerm_private_dns_zone" "container_app_dns" {
  name                = "privatelink.azurecontainerapps.io"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Link the private DNS zone to the virtual network
resource "azurerm_private_dns_zone_virtual_network_link" "container_app_dns_link" {
  name                  = "${var.prefix}-${var.environment}-container-app-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.container_app_dns.name
  virtual_network_id    = var.virtual_network_id
  registration_enabled  = false
  tags                  = var.tags
}

# Private Endpoint for Container App Environment
resource "azurerm_private_endpoint" "container_app_endpoint" {
  name                = "${var.prefix}-${var.environment}-container-app-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.private_endpoint_subnet.id  # Updated to use the new subnet
  tags                = var.tags
  
  private_service_connection {
    name                           = "${var.prefix}-${var.environment}-container-app-psc"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_container_app_environment.container_env.id
    subresource_names              = ["managedEnvironments"]
  }

  private_dns_zone_group {
    name                 = "container-app-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.container_app_dns.id]
  }
}
