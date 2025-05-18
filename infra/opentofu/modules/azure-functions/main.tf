# Azure Functions Module

# Subnet for Azure Functions
resource "azurerm_subnet" "function_subnet" {
  name                 = "function-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = [var.subnet_address_prefix]

  # For Azure private endpoints we need to disable network policies
  private_endpoint_network_policies_enabled = false

  # Service endpoints for Azure Functions
  service_endpoints = ["Microsoft.Web"]
  
  # Add delegation for Azure Functions
  delegation {
    name = "delegation"
    
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}


resource "azurerm_subnet" "function_pe_subnet" {
  name                 = "function-pe-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = [var.subnet_pe_address_prefix]

  # For Azure private endpoints we need to disable network policies
  private_endpoint_network_policies_enabled = false

}

# Storage Account for Azure Functions
resource "azurerm_storage_account" "function_storage" {
  name                     = "${var.prefix}${var.environment}funcsa2"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  tags = var.tags
}

# Enable diagnostic settings for Function Storage Account
resource "azurerm_monitor_diagnostic_setting" "function_storage_diag" {
  name                       = "${var.prefix}-${var.environment}-funcstorage-diag"
  target_resource_id         = azurerm_storage_account.function_storage.id
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

# App Service Plan for Azure Functions
resource "azurerm_service_plan" "function_plan" {
  name                = "${var.prefix}-${var.environment}-function-plan"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = var.os_type
  sku_name            = var.service_plan_sku

  tags = var.tags

  timeouts {
    create = "60m" # Increase timeout to handle throttling
  }
}

# Document Handler Function App
resource "azurerm_linux_function_app" "document_handler" {
  name                          = "${var.prefix}-${var.environment}-GenAI-document-handler1"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  storage_account_name          = azurerm_storage_account.function_storage.name
  storage_account_access_key    = azurerm_storage_account.function_storage.primary_access_key
  service_plan_id               = azurerm_service_plan.function_plan.id
  public_network_access_enabled = var.public_network_access_enabled
  virtual_network_subnet_id     = azurerm_subnet.function_subnet.id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_stack {
      python_version = var.python_version
    }
    application_insights_key = var.app_insights_instrumentation_key
    vnet_route_all_enabled   = true

    cors {
      allowed_origins = ["https://portal.azure.com"]
    }
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"       = "python"
    "APPINSIGHTS_INSTRUMENTATIONKEY" = var.app_insights_instrumentation_key
    "AzureWebJobsStorage"            = azurerm_storage_account.function_storage.primary_connection_string
    "DOCUMENTS_CONTAINER_NAME"       = var.documents_container_name
    "KEYVAULT_URL"                   = var.key_vault_uri
    "DOC_PROCESSING_THRESHOLD"       = var.doc_processing_threshold
    "WEBSITE_RUN_FROM_PACKAGE"       = "1"
    "WEBSITE_CONTENTOVERVNET"        = "1"
    "WEBSITE_VNET_ROUTE_ALL"         = ""
    "BACKEND_USERNAME"               = var.backend_admin_user
    "BACKEND_PASSWORD"               = var.backend_admin_pw
    "INTERNAL_REQUEST_TIMEOUT_LIMIT" = "600"
    "SERVICEBUS_CONNECTION"          = var.servicebus_connection_string
    "SHORT_DOC_QUEUE_NAME"           = var.short_doc_queue_name
    "LONG_DOC_QUEUE_NAME"            = var.long_doc_queue_name
    "AZ_FUNC_BACKEND_URL"            = ""
    "SLACK_WEBHOOK_URL"              = ""
    "PCR_GET_DOCS_CREDS"             = ""
  }

  tags = var.tags
}

# Enable diagnostic settings for Document Handler Function App
resource "azurerm_monitor_diagnostic_setting" "document_handler_diag" {
  name                       = "${var.prefix}-${var.environment}-dochandler-diag"
  target_resource_id         = azurerm_linux_function_app.document_handler.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "FunctionAppLogs"
  }

  metric {
    category = "AllMetrics"
  }
}

# File Processor Function App
resource "azurerm_linux_function_app" "file_processor" {
  name                          = "${var.prefix}-${var.environment}-GenAI-file-processor1"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  storage_account_name          = azurerm_storage_account.function_storage.name
  storage_account_access_key    = azurerm_storage_account.function_storage.primary_access_key
  service_plan_id               = azurerm_service_plan.function_plan.id
  public_network_access_enabled = var.public_network_access_enabled
  virtual_network_subnet_id     = azurerm_subnet.function_subnet.id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_stack {
      python_version = var.python_version
    }
    application_insights_key = var.app_insights_instrumentation_key
    vnet_route_all_enabled   = true

    cors {
      allowed_origins = ["https://portal.azure.com"]
    }
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"            = "python"
    "APPINSIGHTS_INSTRUMENTATIONKEY"      = var.app_insights_instrumentation_key
    "AzureWebJobsStorage"                 = azurerm_storage_account.function_storage.primary_connection_string
    "DOCUMENTS_STORAGE_CONNECTION_STRING" = var.storage_account_connection_string
    "KEYVAULT_URL"                        = var.key_vault_uri
    "WEBSITE_RUN_FROM_PACKAGE"            = "1"
    "WEBSITE_CONTENTOVERVNET"             = "1"
    "WEBSITE_VNET_ROUTE_ALL"              = "1"
    "BACKEND_USERNAME"                    = var.backend_admin_user
    "BACKEND_PASSWORD"                    = var.backend_admin_pw
    "INTERNAL_REQUEST_TIMEOUT_LIMIT"      = "600"
    "SERVICEBUS_CONNECTION"               = var.servicebus_connection_string
    "SHORT_DOC_QUEUE_NAME"                = var.short_doc_queue_name
    "LONG_DOC_QUEUE_NAME"                 = var.long_doc_queue_name
    "AZ_FUNC_BACKEND_URL"                 = ""
    "DOC_PROCESSING_THRESHOLD"            = var.doc_processing_threshold
  }

  tags = var.tags
}

# Enable diagnostic settings for File Processor Function App
resource "azurerm_monitor_diagnostic_setting" "file_processor_diag" {
  name                       = "${var.prefix}-${var.environment}-fileproc-diag"
  target_resource_id         = azurerm_linux_function_app.file_processor.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "FunctionAppLogs"
  }

  metric {
    category = "AllMetrics"
  }
}

# Private DNS Zone for Azure Web Sites
resource "azurerm_private_dns_zone" "web_sites_dns_zone" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Link the Private DNS Zone to the Virtual Network
resource "azurerm_private_dns_zone_virtual_network_link" "web_sites_dns_link" {
  name                  = "${var.prefix}-${var.environment}-web-sites-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.web_sites_dns_zone.name
  virtual_network_id    = var.virtual_network_id
  tags                  = var.tags
}

# Private Endpoint for Document Handler Function App
resource "azurerm_private_endpoint" "document_handler_endpoint" {
  name                = "${var.prefix}-${var.environment}-document-handler-endpoint"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.function_pe_subnet.id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.prefix}-${var.environment}-document-handler-connection"
    private_connection_resource_id = azurerm_linux_function_app.document_handler.id
    is_manual_connection           = false
    subresource_names              = ["sites"]
  }

  private_dns_zone_group {
    name                 = "document-handler-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.web_sites_dns_zone.id]
  }
}

# Private Endpoint for File Processor Function App
resource "azurerm_private_endpoint" "file_processor_endpoint" {
  name                = "${var.prefix}-${var.environment}-file-processor-endpoint"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.function_pe_subnet.id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.prefix}-${var.environment}-file-processor-connection"
    private_connection_resource_id = azurerm_linux_function_app.file_processor.id
    is_manual_connection           = false
    subresource_names              = ["sites"]
  }

  private_dns_zone_group {
    name                 = "file-processor-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.web_sites_dns_zone.id]
  }
}

# Private DNS Zone for Azure Blob Storage
resource "azurerm_private_dns_zone" "blob_storage_dns_zone" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Link the Blob Storage Private DNS Zone to the Virtual Network
# resource "azurerm_private_dns_zone_virtual_network_link" "blob_storage_dns_link" {
#   name                  = "${var.prefix}-${var.environment}-blob-storage-dns-link"
#   resource_group_name   = var.resource_group_name
#   private_dns_zone_name = azurerm_private_dns_zone.blob_storage_dns_zone.name
#   virtual_network_id    = var.virtual_network_id
#   tags                  = var.tags
# }

# Private Endpoint for Function Storage Account
resource "azurerm_private_endpoint" "function_storage_endpoint" {
  name                = "${var.prefix}-${var.environment}-function-storage-endpoint"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.function_pe_subnet.id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.prefix}-${var.environment}-function-storage-connection"
    private_connection_resource_id = azurerm_storage_account.function_storage.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "function-storage-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob_storage_dns_zone.id]
  }
}
