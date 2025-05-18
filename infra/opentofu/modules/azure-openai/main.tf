# Azure OpenAI Service module

# Azure OpenAI Service
resource "azurerm_cognitive_account" "openai" {
  name                          = "${var.prefix}-${var.environment}-openai"
  location                      = var.openai_location
  resource_group_name           = var.resource_group_name
  kind                          = "OpenAI"
  sku_name                      = var.openai_sku
  public_network_access_enabled = false
  custom_subdomain_name         = "${var.prefix}-${var.environment}-openai"
  

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# Enable diagnostic settings for OpenAI
resource "azurerm_monitor_diagnostic_setting" "openai_diag" {
  name                       = "${var.prefix}-${var.environment}-openai-diag"
  target_resource_id         = azurerm_cognitive_account.openai.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  
  enabled_log {
    category = "Audit"
  }
  
  enabled_log {
    category = "RequestResponse"
  }
  
  enabled_log {
    category = "Trace"
  }
  
  metric {
    category = "AllMetrics"
  }
}

# Subnet for Private Endpoints
resource "azurerm_subnet" "openai_subnet" {
  name                 = "openai-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = [var.subnet_address_prefix]
  
  # For Azure private endpoints we need to disable network policies
  private_endpoint_network_policies_enabled = false
  
  # Enforce private network access
  service_endpoints = ["Microsoft.CognitiveServices"]

  depends_on = [azurerm_cognitive_account.openai]
}

# Private Endpoint for OpenAI
resource "azurerm_private_endpoint" "openai_endpoint" {
  name                = "${var.prefix}-${var.environment}-openai-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.openai_subnet.id

  depends_on = [azurerm_subnet.openai_subnet]

  private_service_connection {
    name                           = "${var.prefix}-${var.environment}-openai-psc"
    private_connection_resource_id = azurerm_cognitive_account.openai.id
    is_manual_connection           = false
    subresource_names              = ["account"]
  }

  tags = var.tags
}

resource "azurerm_private_dns_zone" "openai_dns" {
  name                = "privatelink.openai.azure.com"
  resource_group_name = var.resource_group_name
  tags = var.tags

  depends_on = [azurerm_private_endpoint.openai_endpoint]
}

resource "azurerm_private_dns_zone_virtual_network_link" "openai_dns_link" {
  name                  = "openai-dns-link"
  private_dns_zone_name = azurerm_private_dns_zone.openai_dns.name
  resource_group_name   = var.resource_group_name
  virtual_network_id    = var.virtual_network_id
  tags                  = var.tags

  depends_on = [azurerm_private_dns_zone.openai_dns]
}
resource "azurerm_private_dns_zone_virtual_network_link" "openai_dns_link_secondary" {
  name                  = "openai-dns-link-secondary"
  private_dns_zone_name = azurerm_private_dns_zone.openai_dns.name
  resource_group_name   = var.resource_group_name
  virtual_network_id    = var.secondary_virtual_network_id
  tags                  = var.tags

  depends_on = [azurerm_private_dns_zone.openai_dns]
}

resource "azurerm_private_dns_a_record" "openai_dns_record" {
  name                = azurerm_cognitive_account.openai.name
  zone_name           = azurerm_private_dns_zone.openai_dns.name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.openai_endpoint.private_service_connection.0.private_ip_address]
  tags = var.tags

  depends_on = [azurerm_private_dns_zone_virtual_network_link.openai_dns_link,
                azurerm_private_dns_zone_virtual_network_link.openai_dns_link_secondary]
}

# GPT-4 Deployment
resource "azurerm_cognitive_deployment" "gpt_model" {
  name                 = var.gpt_model_name
  cognitive_account_id = azurerm_cognitive_account.openai.id
  depends_on           = [azurerm_private_endpoint.openai_endpoint]

  model {
    format  = "OpenAI"
    name    = var.gpt_model_name
    version = var.gpt_model_version
  }

  scale {
    # type     = "Global Standard" 
    type     = var.gpt_scale_type
    capacity = var.gpt_model_capacity
  }
}

# Embeddings Deployment
resource "azurerm_cognitive_deployment" "embeddings" {
  name                 = var.embeddings_model_name
  cognitive_account_id = azurerm_cognitive_account.openai.id

  model {
    format  = "OpenAI"
    name    = var.embeddings_model_name
    version = var.embeddings_model_version
  }

  scale {
    type     = "Standard"
    capacity = var.embeddings_capacity
  }
}
