# Subnet for AKS
resource "azurerm_subnet" "aks_subnet" {
  name                 = "aks-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = [var.subnet_address_prefix]
}

# Azure Kubernetes Service
resource "azurerm_kubernetes_cluster" "aks" {
  name                    = "${var.prefix}-${var.environment}-aks"
  location                = var.location
  resource_group_name     = var.resource_group_name
  dns_prefix              = "${var.prefix}-${var.environment}-k8s"
  kubernetes_version      = var.kubernetes_version
  private_cluster_enabled = var.private_cluster_enabled
  sku_tier = "Standard"

  depends_on = [azurerm_subnet.aks_subnet]

  default_node_pool {
    name                = "default"
    vm_size             = var.vm_size
    os_disk_size_gb     = var.os_disk_size_gb
    enable_auto_scaling = true
    min_count           = var.min_node_count
    max_count           = var.max_node_count
    vnet_subnet_id      = azurerm_subnet.aks_subnet.id

    upgrade_settings {
      max_surge = "10%"
    }
  }

  network_profile {
    network_plugin     = var.network_plugin
    network_policy     = var.network_policy
    load_balancer_sku  = var.load_balancer_sku
    service_cidr       = var.service_cidr
    dns_service_ip     = var.dns_service_ip
    # docker_bridge_cidr = var.docker_bridge_cidr
  }


  # ingress_application_gateway {
  #   effective_gateway_id = azurerm_application_gateway.app_gateway.id
  #   gateway_id = azurerm_application_gateway.app_gateway.id
  #   ingress_application_gateway_identity {
  #     client_id = azurerm_application_gateway.app_gateway.identity[0].client_id
  #     object_id = azurerm_application_gateway.app_gateway.identity[0].object_id
  #     user_assigned_identity_id = azurerm_user_assigned_identity.app_gateway_identity.id
  #   }
  # }

  identity {
    type = "SystemAssigned"
  }

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  monitor_metrics {
    annotations_allowed = var.annotations_allowed
    labels_allowed      = var.labels_allowed
  }

  tags = var.tags
  
  # Prevent changes to the AKS cluster after creation
  lifecycle {
    ignore_changes = [
      kubernetes_version,
      default_node_pool,
      ingress_application_gateway,
      azure_policy_enabled,
      cost_analysis_enabled,
      default_node_pool[0].upgrade_settings
    ]
  }
}

# Enable diagnostic settings for AKS cluster
resource "azurerm_monitor_diagnostic_setting" "aks_diag" {
  name                       = "${var.prefix}-${var.environment}-aks-diag"
  target_resource_id         = azurerm_kubernetes_cluster.aks.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "kube-apiserver"
  }

  enabled_log {
    category = "kube-audit"
  }

  enabled_log {
    category = "kube-audit-admin"
  }

  enabled_log {
    category = "kube-controller-manager"
  }

  enabled_log {
    category = "kube-scheduler"
  }

  enabled_log {
    category = "cluster-autoscaler"
  }

  enabled_log {
    category = "guard"
  }

  metric {
    category = "AllMetrics"
  }
}

# Grant AKS cluster access to ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  count                = var.acr_id != "" ? 1 : 0
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name = "AcrPull"
  scope                = var.acr_id
  
  depends_on = [
    azurerm_kubernetes_cluster.aks
  ]
}
