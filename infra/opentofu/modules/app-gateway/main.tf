resource "azurerm_subnet" "appgw_subnet" {
  name                 = "apgw-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = [var.subnet_address_prefix]
}

# Create public IP for Application Gateway
resource "azurerm_public_ip" "appgw_ip" {
  name                = "${var.prefix}-${var.environment}-ip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  domain_name_label   = "${var.prefix}-${var.environment}-external"
  sku                 = "Standard"
  tags                = var.tags
}

# Create Web Application Firewall Policy
resource "azurerm_web_application_firewall_policy" "waf_policy" {
  name                = "${var.prefix}-${var.environment}-waf-policy"
  resource_group_name = var.resource_group_name
  location            = var.location

  policy_settings {
    enabled                     = true
    mode                        = var.waf_mode
    request_body_check          = true
    max_request_body_size_in_kb = 128
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }

  tags = var.tags
}

# Create Application Gateway
resource "azurerm_application_gateway" "appgw" {
  name                = "${var.prefix}-${var.environment}-agw"
  resource_group_name = var.resource_group_name
  location            = var.location
  firewall_policy_id  = azurerm_web_application_firewall_policy.waf_policy.id
  tags                = var.tags

  sku {
    name     = var.sku_name
    tier     = var.sku_tier
    capacity = var.capacity
  }

  gateway_ip_configuration {
    name      = "appgw-ip-config"
    subnet_id = azurerm_subnet.appgw_subnet.id
  }

  frontend_ip_configuration {
    name                 = "appgw-frontend-ip-config"
    public_ip_address_id = azurerm_public_ip.appgw_ip.id
  }

  frontend_ip_configuration {
    name                          = "appgw-private-frontend-ip-config"
    subnet_id                     = azurerm_subnet.appgw_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.private_ip_address
  }

  frontend_port {
    name = "appgw-frontend-port"
    port = 80
  }

  frontend_port {
    name = "appgw-frontend-port-https"
    port = 443
  }

  backend_address_pool {
    name = "default-backend-pool"
  }

  backend_http_settings {
    name                  = "default-http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = "default-http-listener"
    frontend_ip_configuration_name = "appgw-frontend-ip-config"
    frontend_port_name             = "appgw-frontend-port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "default-routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "default-http-listener"
    backend_address_pool_name  = "default-backend-pool"
    backend_http_settings_name = "default-http-settings"
    priority                   = var.priority
  }
}

# Enable diagnostic settings for Application Gateway
resource "azurerm_monitor_diagnostic_setting" "appgw_diag" {
  name                       = "${var.prefix}-${var.environment}-appgw-diag"
  target_resource_id         = azurerm_application_gateway.appgw.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "ApplicationGatewayAccessLog"
  }

  enabled_log {
    category = "ApplicationGatewayPerformanceLog"
  }

  enabled_log {
    category = "ApplicationGatewayFirewallLog"
  }

  metric {
    category = "AllMetrics"
  }
}

# Create private DNS zone for internal service communication
resource "azurerm_private_dns_zone" "private_dns" {
  count               = var.create_private_dns ? 1 : 0
  name                = "${var.prefix}.${var.environment}.internal"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Link private DNS zone to the virtual network
resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link" {
  count                 = var.create_private_dns ? 1 : 0
  name                  = "link-to-aks-vnet"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.private_dns[0].name
  virtual_network_id    = var.virtual_network_id
  registration_enabled  = false
  tags                  = var.tags
}

# Add A record for the bot service if IP is provided
resource "azurerm_private_dns_a_record" "bot_record" {
  count               = var.create_private_dns && var.bot_service_private_ip != "" ? 1 : 0
  name                = "bot"
  zone_name           = azurerm_private_dns_zone.private_dns[0].name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [var.bot_service_private_ip]
  tags                = var.tags
}