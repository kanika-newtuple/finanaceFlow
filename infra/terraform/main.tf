terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  # backend "azurerm" {
  #     resource_group_name  = "tfstate"
  #     storage_account_name = "${var.prefix}${var.environment}storage"
  #     container_name       = "tfstate"
  #     key                  = "terraform.tfstate"
  # }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id = var.azure_subscription_id
  tenant_id       = var.azure_tenant_id
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-${var.environment}-rg"
  location = var.location
  tags     = var.tags
}

# Virtual Network for the infrastructure
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-${var.environment}-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [var.vnet_address_space]
  tags                = var.tags
}


# Service Bus using module
module "service_bus" {
  source = "./modules/servicebus"

  prefix                     = var.prefix
  environment                = var.environment
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  servicebus_sku             = var.servicebus_sku
  servicebus_capacity        = var.servicebus_capacity
  virtual_network_name       = azurerm_virtual_network.vnet.name
  virtual_network_id         = azurerm_virtual_network.vnet.id
  subnet_address_prefix      = var.servicebus_address_prefix
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  queues = [
    {
      name               = var.short_doc_queue_name
      max_size_mb        = var.queue_max_size_mb
      message_ttl        = var.queue_message_ttl
      max_delivery_count = var.max_delivery_count
      lock_duration      = "PT5M"
    },
    {
      name               = var.long_doc_queue_name
      max_size_mb        = var.queue_max_size_mb
      message_ttl        = var.queue_message_ttl
      max_delivery_count = var.max_delivery_count
      lock_duration      = "PT5M"
    },
    {
      name               = var.msbilling_queue_name
      max_size_mb        = var.queue_max_size_mb
      message_ttl        = var.queue_message_ttl
      max_delivery_count = var.max_delivery_count
      lock_duration      = "PT5M"
    }
  ]

  tags = var.tags
}

# Storage module for documents
module "storage" {
  source = "./modules/storage"

  prefix                        = var.prefix
  environment                   = var.environment
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  account_tier                  = "Standard"
  account_replication_type      = "LRS"
  container_name                = var.storage_container_name
  container_access_type         = "private"
  vnet                          = azurerm_virtual_network.vnet
  tags                          = var.tags
  storage_subnet_address_prefix = var.storage_subnet_address_prefix
  log_analytics_workspace_id    = azurerm_log_analytics_workspace.law.id
}



# Application Insights for monitoring
resource "azurerm_application_insights" "app_insights" {
  name                = "${var.prefix}-${var.environment}-app-insights"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
  tags                = var.tags
}

# Enable diagnostic settings for Application Insights
resource "azurerm_monitor_diagnostic_setting" "app_insights_diag" {
  name                       = "${var.prefix}-${var.environment}-appinsights-diag"
  target_resource_id         = azurerm_application_insights.app_insights.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  enabled_log {
    category = "AppAvailabilityResults"
  }

  enabled_log {
    category = "AppEvents"
  }

  enabled_log {
    category = "AppMetrics"
  }

  enabled_log {
    category = "AppDependencies"
  }

  enabled_log {
    category = "AppExceptions"
  }

  enabled_log {
    category = "AppRequests"
  }

  enabled_log {
    category = "AppTraces"
  }

  metric {
    category = "AllMetrics"
  }
}

# Azure Key Vault
resource "azurerm_key_vault" "key_vault" {
  name                       = "${var.prefix}-${var.environment}-kv"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  tenant_id                  = var.azure_tenant_id
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  sku_name                   = "standard"
  enable_rbac_authorization  = true # Keeping RBAC authorization enabled as it appears this is how the existing vault was set up
  tags                       = var.tags
}

# Enable diagnostic settings for Key Vault
resource "azurerm_monitor_diagnostic_setting" "key_vault_diag" {
  name                       = "${var.prefix}-${var.environment}-kv-diag"
  target_resource_id         = azurerm_key_vault.key_vault.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

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

# Instead of access policies, use RBAC role assignments for Key Vault permissions
resource "azurerm_role_assignment" "deployment_user_role" {
  scope                = azurerm_key_vault.key_vault.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "document_handler_role" {
  scope                = azurerm_key_vault.key_vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.azure_functions.document_handler_principal_id
}

resource "azurerm_role_assignment" "file_processor_role" {
  scope                = azurerm_key_vault.key_vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.azure_functions.file_processor_principal_id
}


# Subnet for ACR private endpoint
resource "azurerm_subnet" "acr_subnet" {
  name                 = "acr-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.acr_address_prefix]

  # For Azure private endpoints we need to disable network policies
  private_endpoint_network_policies_enabled = true
  service_endpoints                         = ["Microsoft.ContainerRegistry"]
}

# Use ACR module instead of inline resources
module "acr" {
  source = "./modules/acr"

  prefix              = var.prefix
  environment         = var.environment
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Premium" # Premium tier is required for private endpoints
  admin_enabled       = true
  dummy_image_tag     = "v1"

  # Private endpoint configuration
  enable_private_endpoint       = true
  subnet_id                     = azurerm_subnet.acr_subnet.id
  virtual_network_id            = azurerm_virtual_network.vnet.id
  public_network_access_enabled = true # Disable public access to force private connections

  # Pass AKS kubelet identity object ID to enable ACR pull
  aks_kubelet_identity_object_id = module.aks.aks_kubelet_identity[0].object_id

  # Log Analytics Workspace ID for diagnostic settings
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  tags = var.tags
}


# Use Container App Environment module
module "container_app_environment" {
  source = "./modules/container-app-env"

  prefix              = var.prefix
  environment         = var.environment
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  virtual_network_name     = azurerm_virtual_network.vnet.name
  virtual_network_id       = azurerm_virtual_network.vnet.id
  subnet_address_prefix    = var.container_app_subnet_address_prefix
  pe_subnet_address_prefix = var.container_app_pe_subnet_address_prefix

  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  workload_profiles = [
    {
      name                  = "${var.environment}-wp"
      workload_profile_type = "D4"
      minimum_count         = 3 # Recommended
      maximum_count         = 3 # Recommended
    }
  ]

  tags = var.tags

  depends_on = [module.acr]
}

# Use Container App Job module for short Doc Processor
module "short_doc_processor_job" {
  source = "./modules/container-app-job"

  environment                  = var.environment
  job_name                     = "shortdoc-processor-job"
  container_app_environment_id = module.container_app_environment.container_app_environment_id
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location

  # Job configuration
  replica_timeout_in_seconds  = 3600
  replica_retry_limit         = 1
  parallelism                 = 50
  replica_completion_count    = 1
  min_executions              = 0
  max_executions              = 8
  polling_interval_in_seconds = 60

  # Service Bus configuration
  servicebus_namespace_name    = module.service_bus.namespace_name
  queue_name                   = var.short_doc_queue_name
  message_count_threshold      = var.short_doc_processing_threshold
  servicebus_connection_string = module.service_bus.default_primary_connection_string

  # Container registry configuration
  acr_login_server = module.acr.acr_login_server
  acr_username     = module.acr.acr_admin_username
  acr_password     = module.acr.acr_admin_password

  # Container configuration
  container_name = "dummyimage"
  image_name     = "dummyimage"
  image_version  = var.doc_processor_image_version
  cpu            = 2.0
  memory         = "4Gi"

  tags = var.tags

  depends_on = [module.acr]
}

# Use Container App Job module for long Doc Processor
module "long_doc_processor_job" {
  source = "./modules/container-app-job"

  environment                  = var.environment
  job_name                     = "longdoc-processor-job"
  container_app_environment_id = module.container_app_environment.container_app_environment_id
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location

  # Job configuration
  replica_timeout_in_seconds  = 3600
  replica_retry_limit         = 1
  parallelism                 = 50
  replica_completion_count    = 1
  min_executions              = 0
  max_executions              = 8
  polling_interval_in_seconds = 60

  # Service Bus configuration
  servicebus_namespace_name    = module.service_bus.namespace_name
  queue_name                   = var.long_doc_queue_name
  message_count_threshold      = var.long_doc_processing_threshold
  servicebus_connection_string = module.service_bus.default_primary_connection_string

  # Container registry configuration
  acr_login_server = module.acr.acr_login_server
  acr_username     = module.acr.acr_admin_username
  acr_password     = module.acr.acr_admin_password

  # Container configuration
  container_name = "dummyimage"
  image_name     = "dummyimage"
  image_version  = var.doc_processor_image_version
  cpu            = 2.0
  memory         = "4Gi"

  tags = var.tags

  depends_on = [module.acr]
}

# Grafana & Prometheus for AKS Monitoring
resource "azurerm_monitor_workspace" "prometheus_workspace" {
  name                = "${var.prefix}-${var.environment}-prometheus"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = var.tags
}

# Use Container App Job module for long Doc Processor
module "msbilling_doc_processor_job" {
  source = "./modules/container-app-job"

  environment                  = var.environment
  job_name                     = "msbillingdoc-processor-job"
  container_app_environment_id = module.container_app_environment.container_app_environment_id
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location

  # Job configuration
  replica_timeout_in_seconds  = 3600
  replica_retry_limit         = 1
  parallelism                 = 50
  replica_completion_count    = 1
  min_executions              = 0
  max_executions              = 8
  polling_interval_in_seconds = 60

  # Service Bus configuration
  servicebus_namespace_name    = module.service_bus.namespace_name
  queue_name                   = var.long_doc_queue_name
  message_count_threshold      = var.long_doc_processing_threshold
  servicebus_connection_string = module.service_bus.default_primary_connection_string

  # Container registry configuration
  acr_login_server = module.acr.acr_login_server
  acr_username     = module.acr.acr_admin_username
  acr_password     = module.acr.acr_admin_password

  # Container configuration
  container_name = "msbillingdoc"
  image_name     = "dummyimage"
  image_version  = var.doc_processor_image_version
  cpu            = 2.0
  memory         = "4Gi"

  tags = var.tags

  depends_on = [module.acr]
}



# Use Application Gateway module
module "application_gateway" {
  source              = "./modules/app-gateway"
  prefix              = var.prefix
  environment         = var.environment
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  virtual_network_name  = azurerm_virtual_network.vnet.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  subnet_address_prefix = var.appgw_subnet_address_prefix
  private_ip_address    = var.appgw_private_ip_address

  waf_mode               = "Detection"
  sku_name               = "WAF_v2"
  sku_tier               = "WAF_v2"
  capacity               = 2
  priority               = 100
  create_private_dns     = true
  bot_service_private_ip = var.bot_service_private_ip

  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  tags = var.tags
}

# Enable AGIC (Application Gateway Ingress Controller) add-on for AKS
resource "azurerm_role_assignment" "aks_agic_role" {
  scope                = module.application_gateway.app_gateway_id
  role_definition_name = "Contributor"
  principal_id         = module.aks.aks_identity.principal_id
}

# The AKS module should be updated to include the AGIC addon configuration
# This is typically done inside the module itself, but we can add a local-exec provisioner 
# as a workaround if the module doesn't support it
resource "null_resource" "enable_agic_addon" {
  depends_on = [module.aks, module.application_gateway, azurerm_role_assignment.aks_agic_role]

  provisioner "local-exec" {
    command = <<EOT
      az aks enable-addons \
        --name ${module.aks.aks_name} \
        --resource-group ${azurerm_resource_group.rg.name} \
        --addons ingress-appgw \
        --appgw-id ${module.application_gateway.app_gateway_id}
    EOT
  }
}




# Use AKS module instead of inline resources
module "aks" {
  source = "./modules/aks"

  prefix                     = var.prefix
  environment                = var.environment
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  virtual_network_name       = azurerm_virtual_network.vnet.name
  subnet_address_prefix      = var.aks_subnet_address_prefix
  private_lb_ip_address      = var.aks_private_lb_ip_address
  kubernetes_version         = var.kubernetes_version
  vm_size                    = var.vm_size
  min_node_count             = var.min_node_count
  max_node_count             = var.max_node_count
  private_cluster_enabled    = var.private_cluster
  network_plugin             = "azure"
  network_policy             = "calico"
  load_balancer_sku          = "standard"
  service_cidr               = var.aks_service_cidr
  dns_service_ip             = var.aks_dns_service_ip
  docker_bridge_cidr         = var.aks_docker_bridge_cidr
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  annotations_allowed        = "app"
  labels_allowed             = "app"
  tags                       = var.tags
}

## endregion AKS

# Use the jumpbox module instead of inline resources
module "jumpbox" {
  source = "./modules/jumpbox"

  prefix               = var.prefix
  environment          = var.environment
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name

  allowed_ssh_source_ips    = var.allowed_ssh_source_ips
  jumpbox_vm_size           = var.jumpbox_vm_size
  jumpbox_admin_username    = var.jumpbox_admin_username
  jumpbox_ssh_public_key    = var.jumpbox_ssh_public_key
  jumpbox_setup_script_path = "${path.module}/scripts/jumpbox_setup.sh"
  tenant_id                 = var.azure_tenant_id

  tags = var.tags
}

# Log Analytics Workspace for AKS monitoring
resource "azurerm_log_analytics_workspace" "law" {
  name                = "${var.prefix}-${var.environment}-law"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

# Use PostgreSQL module instead of inline resources
module "postgres" {
  source = "./modules/postgresql"

  prefix                     = var.prefix
  environment                = var.environment
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  virtual_network_name       = azurerm_virtual_network.vnet.name
  virtual_network_id         = azurerm_virtual_network.vnet.id
  subnet_address_prefix      = var.postgres_subnet_address_prefix
  postgres_admin_password    = var.postgres_admin_password
  storage_mb                 = var.postgres_storage_mb
  vcore_count                = 2
  node_count                 = 0 # Zero nodes means single coordinator mode
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  tags = var.tags
}

# Use Azure Functions module instead of inline resources
module "azure_functions" {
  source = "./modules/azure-functions"

  prefix                = var.prefix
  environment           = var.environment
  subnet_pe_address_prefix = var.subnet_pe_address_prefix
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  virtual_network_name  = azurerm_virtual_network.vnet.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  subnet_address_prefix = var.function_subnet_address_prefix

  app_insights_instrumentation_key  = azurerm_application_insights.app_insights.instrumentation_key
  key_vault_uri                     = azurerm_key_vault.key_vault.vault_uri
  servicebus_connection_string      = module.service_bus.default_primary_connection_string
  short_doc_queue_name              = module.service_bus.queues["short-doc-queue"].name
  long_doc_queue_name               = module.service_bus.queues["long-doc-queue"].name
  storage_account_connection_string = module.storage.primary_connection_string

  backend_admin_user       = var.backend_admin_user
  backend_admin_pw         = var.backend_admin_pw
  doc_processing_threshold = var.doc_processing_threshold
  postgres_admin_password  = var.postgres_admin_password
  postgres_server_name     = module.postgres.postgres_name
  documents_container_name = module.storage.container_name

  public_network_access_enabled = false
  os_type                       = "Linux"
  python_version                = "3.11"
  service_plan_sku              = "B1"
  log_analytics_workspace_id    = azurerm_log_analytics_workspace.law.id

  tags = var.tags
}

# Add client_config data source for Key Vault policies
data "azurerm_client_config" "current" {}

# Azure Monitor Action Group
resource "azurerm_monitor_action_group" "critical_alerts" {
  name                = "${var.prefix}-${var.environment}-critical-alerts"
  resource_group_name = azurerm_resource_group.rg.name
  short_name          = "critical"

  email_receiver {
    name                    = "admin"
    email_address           = var.alert_email
    use_common_alert_schema = true
  }

  tags = var.tags
}

# Azure Monitor Alert for high CPU usage in AKS
resource "azurerm_monitor_metric_alert" "aks_cpu_alert" {
  name                = "${var.prefix}-${var.environment}-aks-cpu-alert"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [module.aks.aks_id]
  description         = "Action will be triggered when CPU usage exceeds threshold"
  severity            = 2

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_cpu_usage_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.critical_alerts.id
  }

  tags = var.tags
}

resource "azurerm_dashboard_grafana" "grafana" {
  name                              = "${var.prefix}-${var.environment}-grafana"
  resource_group_name               = azurerm_resource_group.rg.name
  location                          = azurerm_resource_group.rg.location
  grafana_major_version             = var.grafana_major_version
  api_key_enabled                   = true
  deterministic_outbound_ip_enabled = true
  public_network_access_enabled     = var.grafana_public_access

  identity {
    type = "SystemAssigned"
  }

  azure_monitor_workspace_integrations {
    resource_id = azurerm_monitor_workspace.prometheus_workspace.id
  }

  tags = var.tags
}

# Enable Prometheus metrics collection for AKS
resource "azurerm_monitor_data_collection_endpoint" "aks_dce" {
  name                = "${var.prefix}-${var.environment}-dce"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  kind                = "Linux"
  tags                = var.tags
}

resource "azurerm_monitor_data_collection_rule" "aks_dcr" {
  name                        = "${var.prefix}-${var.environment}-aks-dcr"
  resource_group_name         = azurerm_resource_group.rg.name
  location                    = azurerm_resource_group.rg.location
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.aks_dce.id

  destinations {
    monitor_account {
      monitor_account_id = azurerm_monitor_workspace.prometheus_workspace.id
      name               = "prometheus-workspace"
    }
  }

  data_flow {
    destinations = ["prometheus-workspace"]
    streams      = ["Microsoft-PrometheusMetrics"]
  }

  data_sources {
    prometheus_forwarder {
      streams = ["Microsoft-PrometheusMetrics"]
      name    = "aks-prometheus"
    }
  }

  description = "DCR for AKS Prometheus metrics"
  tags        = var.tags
}

# Associate the DCR with the AKS cluster
resource "azurerm_monitor_data_collection_rule_association" "aks_dcra" {
  name                    = "${var.prefix}-${var.environment}-aks-dcra"
  target_resource_id      = module.aks.aks_id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.aks_dcr.id
  description             = "Association of DCR for AKS Prometheus metrics"
}

# Grafana Access Control - Assign Grafana Admin Role
resource "azurerm_role_assignment" "grafana_admin" {
  count                = length(var.grafana_admin_object_ids)
  scope                = azurerm_dashboard_grafana.grafana.id
  role_definition_name = "Grafana Admin"
  principal_id         = var.grafana_admin_object_ids[count.index]
}

# Create Managed Prometheus Alert Rules
resource "azurerm_monitor_alert_prometheus_rule_group" "node_recording_rules" {
  name                = "nodeRecordingRules"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  cluster_name        = module.aks.aks_name
  scopes              = [azurerm_monitor_workspace.prometheus_workspace.id]
  interval            = "PT1M"
  rule {
    record     = "instance:node_cpu:rate:sum"
    expression = "sum(rate(node_cpu_seconds_total{mode!=\"idle\",mode!=\"iowait\"}[1m])) by (instance)"
  }
  rule {
    record     = "instance:node_memory_utilization:ratio"
    expression = "1 - ((node_memory_MemFree_bytes + node_memory_Cached_bytes + node_memory_Buffers_bytes) / node_memory_MemTotal_bytes)"
  }
  rule {
    record     = "instance:node_network_receive_bytes:rate:sum"
    expression = "sum(rate(node_network_receive_bytes_total[1m])) by (instance)"
  }
  rule {
    record     = "instance:node_network_transmit_bytes:rate:sum"
    expression = "sum(rate(node_network_transmit_bytes_total[1m])) by (instance)"
  }
}

resource "azurerm_monitor_alert_prometheus_rule_group" "node_alert_rules" {
  name                = "nodeAlertRules"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  cluster_name        = module.aks.aks_name
  scopes              = [azurerm_monitor_workspace.prometheus_workspace.id]
  interval            = "PT1M"
  rule {
    alert      = "NodeCPUUsage"
    expression = "instance:node_cpu:rate:sum > 0.8"
    for        = "PT5M"
    severity   = 2
    annotations = {
      summary     = "Node CPU usage is high"
      description = "Node CPU usage is above 80% for 5 minutes"
    }
    labels = {
      service = "aks"
    }
    action {
      action_group_id = azurerm_monitor_action_group.critical_alerts.id
    }
  }
  rule {
    alert      = "NodeMemoryUsage"
    expression = "instance:node_memory_utilization:ratio > 0.8"
    for        = "PT5M"
    severity   = 2
    annotations = {
      summary     = "Node memory usage is high"
      description = "Node memory usage is above 80% for 5 minutes"
    }
    labels = {
      service = "aks"
    }
    action {
      action_group_id = azurerm_monitor_action_group.critical_alerts.id
    }
  }
  rule {
    alert      = "NodeDiskPressure"
    expression = "kube_node_status_condition{condition=\"DiskPressure\", status=\"true\"} == 1"
    for        = "PT5M"
    severity   = 2
    annotations = {
      summary     = "Node is experiencing disk pressure"
      description = "Node is under disk pressure"
    }
    labels = {
      service = "aks"
    }
    action {
      action_group_id = azurerm_monitor_action_group.critical_alerts.id
    }
  }
}

# Allow managed Grafana to access Prometheus metrics from AKS
resource "azurerm_role_assignment" "grafana_prometheus_reader" {
  scope                = azurerm_monitor_workspace.prometheus_workspace.id
  role_definition_name = "Monitoring Data Reader"
  principal_id         = azurerm_dashboard_grafana.grafana.identity[0].principal_id
  depends_on           = [azurerm_dashboard_grafana.grafana]
}

# Allow AKS to write metrics to Prometheus workspace
resource "azurerm_role_assignment" "aks_monitoring_metrics_publisher" {
  scope                = azurerm_monitor_workspace.prometheus_workspace.id
  role_definition_name = "Monitoring Metrics Publisher"
  principal_id         = module.aks.aks_identity.principal_id
  depends_on           = [module.aks]
}

# Azure SQL Server - Replace with module
module "sql_server" {
  source = "./modules/azure-sql"

  prefix              = var.prefix
  environment         = var.environment
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  virtual_network_name  = azurerm_virtual_network.vnet.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  subnet_address_prefix = var.sql_subnet_address_prefix

  sql_admin_username = var.sql_admin_username
  sql_admin_password = var.sql_admin_password
  sql_database_sku   = var.sql_database_sku
  max_size_gb        = 100

  public_network_access_enabled = false
  log_analytics_workspace_id    = azurerm_log_analytics_workspace.law.id

  tags = var.tags
}

# Azure OpenAI Service using module
module "azure_openai" {
  source = "./modules/azure-openai"

  prefix                     = var.prefix
  environment                = var.environment
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  openai_location            = var.openai_location
  openai_sku                 = var.openai_sku
  virtual_network_name       = azurerm_virtual_network.vnet.name
  virtual_network_id         = azurerm_virtual_network.vnet.id
  secondary_virtual_network_id = azurerm_virtual_network.vnet_secondary.id
  subnet_address_prefix      = var.openai_subnet_address_prefix
  gpt_model_name             = var.openai_model
  gpt_model_version          = "2024-05-13"
  gpt_model_capacity         = var.openai_model_capacity
  embeddings_model_name      = var.embeddings_model_name
  gpt_scale_type             = var.gpt_scale_type
  embeddings_model_version   = "1"
  embeddings_capacity        = var.embeddings_capacity
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  tags                       = var.tags
}

// region Secondary VNet and OpenAI Service

# Resource Group for secondary resource
# Virtual Network for the secondary OpenAI service
resource "azurerm_virtual_network" "vnet_secondary" {
  name                = "${var.prefix}-${var.environment}-vnet-secondary"
  location            = var.secondary_location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [var.secondary_vnet_address_space]
  tags                = var.tags
}

# VNet Peering from primary to secondary
resource "azurerm_virtual_network_peering" "primary_to_secondary" {
  name                         = "peer-${azurerm_virtual_network.vnet.name}-to-${azurerm_virtual_network.vnet_secondary.name}"
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.vnet_secondary.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

# VNet Peering from secondary to primary
resource "azurerm_virtual_network_peering" "secondary_to_primary" {
  name                         = "peer-${azurerm_virtual_network.vnet_secondary.name}-to-${azurerm_virtual_network.vnet.name}"
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.vnet_secondary.name
  remote_virtual_network_id    = azurerm_virtual_network.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

# Azure OpenAI Service using module for the secondary region
module "azure_openai_secondary" {
  source = "./modules/azure-openai"

  prefix                     = "${var.prefix}-secondary" # Use a modified prefix to ensure unique resource names from the module
  environment                = var.environment
  resource_group_name        = azurerm_resource_group.rg.name
  create_private_dns_zone    = false
  location                   = var.secondary_openai_location # RG location for the Cognitive Account
  openai_location            = var.secondary_openai_location                # OpenAI service specific location
  openai_sku                 = var.secondary_openai_sku
  virtual_network_name       = azurerm_virtual_network.vnet_secondary.name
  virtual_network_id         = azurerm_virtual_network.vnet.id
  secondary_virtual_network_id = azurerm_virtual_network.vnet_secondary.id
  subnet_address_prefix      = var.secondary_openai_subnet_address_prefix
  gpt_model_name             = var.secondary_openai_model # Assuming same model, or use a new variable
  gpt_model_version          = "2025-04-14"     # Assuming same version, or use a new variable
  gpt_model_capacity         = var.secondary_openai_model_capacity
  embeddings_model_name      = var.embeddings_model_name # Assuming same model, or use a new variable
  gpt_scale_type             = var.secondary_gpt_scale_type
  embeddings_model_version   = "1" # Assuming same version, or use a new variable
  embeddings_capacity        = var.secondary_embeddings_capacity
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id # Or a new LAW in the secondary region
  tags                       = var.tags

  depends_on = [
    azurerm_virtual_network_peering.primary_to_secondary,
    azurerm_virtual_network_peering.secondary_to_primary
  ]
}

// endregion Secondary VNet and OpenAI Service
