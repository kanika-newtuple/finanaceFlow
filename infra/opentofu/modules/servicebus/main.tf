# Service Bus Namespace
resource "azurerm_servicebus_namespace" "sb_namespace" {
  name                         = "${var.prefix}-${var.environment}-sb-namespace"
  location                     = var.location
  resource_group_name          = var.resource_group_name
  sku                          = var.servicebus_sku
  capacity                     = var.servicebus_capacity
  premium_messaging_partitions = var.servicebus_sku == "Premium" ? 1 : null
  tags                         = var.tags
  public_network_access_enabled = false
}

# Enable diagnostic settings for Service Bus Namespace
resource "azurerm_monitor_diagnostic_setting" "servicebus_diag" {
  name                       = "${var.prefix}-${var.environment}-sb-diag"
  target_resource_id         = azurerm_servicebus_namespace.sb_namespace.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "OperationalLogs"
    
  }

  enabled_log {
    category = "VNetAndIPFilteringLogs"
      }

  metric {
    category = "AllMetrics"
      }
}

# Create Service Bus queues
resource "azurerm_servicebus_queue" "queues" {
  for_each = { for queue in var.queues : queue.name => queue }
  
  name                                 = "${var.prefix}-${var.environment}-${each.value.name}"
  namespace_id                         = azurerm_servicebus_namespace.sb_namespace.id
  max_size_in_megabytes                = each.value.max_size_mb
  default_message_ttl                  = each.value.message_ttl
  dead_lettering_on_message_expiration = true
  max_delivery_count                   = each.value.max_delivery_count
  lock_duration                        = each.value.lock_duration
}

# Subnet for Service Bus Private Endpoint
resource "azurerm_subnet" "servicebus_subnet" {
  count                = var.create_private_endpoint ? 1 : 0
  
  name                 = "servicebus-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = [var.subnet_address_prefix]
  
  # Enable private endpoint network policies
  private_endpoint_network_policies_enabled = true
}

# Private DNS Zone for Service Bus
resource "azurerm_private_dns_zone" "servicebus_dns" {
  count               = var.create_private_endpoint ? 1 : 0
  
  name                = "privatelink.servicebus.windows.net"
  resource_group_name = var.resource_group_name
}

# Link the Private DNS Zone to the VNet
resource "azurerm_private_dns_zone_virtual_network_link" "servicebus_dns_link" {
  count                = var.create_private_endpoint ? 1 : 0
  
  name                  = "servicebus-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.servicebus_dns[0].name
  virtual_network_id    = var.virtual_network_id
  registration_enabled  = false
}

# Private Endpoint for Service Bus
resource "azurerm_private_endpoint" "servicebus_endpoint" {
  count               = var.create_private_endpoint ? 1 : 0
  
  name                = "${var.prefix}-${var.environment}-servicebus-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.servicebus_subnet[0].id

  private_service_connection {
    name                           = "${var.prefix}-${var.environment}-servicebus-psc"
    private_connection_resource_id = azurerm_servicebus_namespace.sb_namespace.id
    is_manual_connection           = false
    subresource_names              = ["namespace"]
  }

  private_dns_zone_group {
    name                 = "servicebus-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.servicebus_dns[0].id]
  }

  tags = var.tags
}

# DNS A Record for Service Bus Namespace
resource "azurerm_private_dns_a_record" "servicebus_a_record" {
  count               = var.create_private_endpoint ? 1 : 0
  
  name                = azurerm_servicebus_namespace.sb_namespace.name
  zone_name           = azurerm_private_dns_zone.servicebus_dns[0].name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.servicebus_endpoint[0].private_service_connection[0].private_ip_address]
}

# DNS A Record for Service Bus Alias
resource "azurerm_private_dns_a_record" "servicebus_alias_record" {
  count               = var.create_private_endpoint ? 1 : 0
  
  name                = "${azurerm_servicebus_namespace.sb_namespace.name}.${var.location}"
  zone_name           = azurerm_private_dns_zone.servicebus_dns[0].name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.servicebus_endpoint[0].private_service_connection[0].private_ip_address]
}
