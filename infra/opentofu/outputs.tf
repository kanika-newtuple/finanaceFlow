output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "servicebus_namespace_name" {
  value = module.service_bus.namespace_name
}

output "servicebus_connection_string" {
  value     = module.service_bus.default_primary_connection_string
  sensitive = true
}

output "short_doc_queue_name" {
  value = module.service_bus.queues["short-doc-queue"].name
}

output "long_doc_queue_name" {
  value = module.service_bus.queues["long-doc-queue"].name
}

output "storage_account_name" {
  value = module.storage.storage_account_name
}

output "storage_account_access_key" {
  value     = module.storage.primary_connection_string
  sensitive = true
}

output "storage_container_name" {
  value = module.storage.container_name
}

output "application_insights_instrumentation_key" {
  value     = azurerm_application_insights.app_insights.instrumentation_key
  sensitive = true
}

output "key_vault_name" {
  value = azurerm_key_vault.key_vault.name
}

output "key_vault_uri" {
  value = azurerm_key_vault.key_vault.vault_uri
}

output "container_registry_name" {
  value = module.acr.acr_name
}

output "container_registry_login_server" {
  value = module.acr.acr_login_server
}

output "container_registry_admin_username" {
  value     = module.acr.acr_admin_username
  sensitive = true
}

output "container_registry_admin_password" {
  value     = module.acr.acr_admin_password
  sensitive = true
}

# output "kubernetes_cluster_name" {
#   value = azurerm_kubernetes_cluster.aks.name
# }

# output "kubernetes_cluster_host" {
#   value     = azurerm_kubernetes_cluster.aks.kube_config.0.host
#   sensitive = true
# }

# output "kubernetes_cluster_client_certificate" {
#   value     = azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate
#   sensitive = true
# }

# output "kube_config" {
#   value     = azurerm_kubernetes_cluster.aks.kube_config_raw
#   sensitive = true
# }

// Update PostgreSQL outputs
output "postgres_server_name" {
  description = "The name of the PostgreSQL server"
  value       = module.postgres.postgres_name
}


output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.law.id
}

// Grafana & Prometheus outputs
output "grafana_endpoint" {
  value = azurerm_dashboard_grafana.grafana.endpoint
}

output "grafana_id" {
  value = azurerm_dashboard_grafana.grafana.id
}

output "prometheus_workspace_id" {
  value = azurerm_monitor_workspace.prometheus_workspace.id
}

output "prometheus_workspace_name" {
  value = azurerm_monitor_workspace.prometheus_workspace.name
}

output "data_collection_endpoint_id" {
  value = azurerm_monitor_data_collection_endpoint.aks_dce.id
}

output "data_collection_rule_id" {
  value = azurerm_monitor_data_collection_rule.aks_dcr.id
}


output "document_handler_function_url" {
  value       = "https://${module.azure_functions.document_handler_default_hostname}"
  description = "URL for the GenAI-document-handler function app"
}


output "file_processor_function_url" {
  value       = "https://${module.azure_functions.file_processor_default_hostname}"
  description = "URL for the GenAI-file-processor function app"
}

output "function_storage_name" {
  value = module.azure_functions.function_storage_name
}

// Container App Job outputs
output "container_app_environment_name" {
  value = module.container_app_environment.container_app_environment_name
}

# output "long_doc_processor_job_name" {
#   value = azurerm_container_app_job.long_doc_processor_job.name
# }
# output "short_doc_processor_job_name" {
#   value = azurerm_container_app_job.short_doc_processor_job.name
# }

output "container_app_environment_default_domain" {
  value = module.container_app_environment.container_app_environment_default_domain
}

// APIM-related outputs
# output "apim_name" {
#   value = azurerm_api_management.apim.name
#   description = "Name of the API Management service"
# }

# output "apim_private_ip" {
#   value = azurerm_api_management.apim.private_ip_addresses[0]
#   description = "Private IP address of the API Management service"
# }

# output "apim_gateway_url" {
#   value = "https://${azurerm_api_management.apim.name}.azure-api.net"
#   description = "Gateway URL of the API Management service"
# }

# output "apim_document_api_url" {
#   value = "https://${azurerm_api_management.apim.name}.azure-api.net/documents"
#   description = "URL for the document processing API"
# }

# output "jumpbox_public_ip" {
#   value       = azurerm_public_ip.jumpbox_ip.ip_address
#   description = "Public IP address of the jumpbox VM"
# }

# output "jumpbox_connection_string" {
#   value       = "ssh ${var.jumpbox_admin_username}@${azurerm_public_ip.jumpbox_ip.ip_address}"
#   description = "SSH connection string for the jumpbox VM"
# }

// SQL Server outputs
output "sql_server_name" {
  value = module.sql_server.sql_server_name
}

output "sql_server_fqdn" {
  value = module.sql_server.sql_server_fqdn
}

output "sql_database_name" {
  value = module.sql_server.sql_database_name
}

output "sql_connection_string" {
  value     = "Server=${module.sql_server.sql_server_fqdn};Database=${module.sql_server.sql_database_name};User Id=${var.sql_admin_username};Password=${var.sql_admin_password};TrustServerCertificate=False;Encrypt=True;"
  sensitive = true
}

// Azure OpenAI outputs
# output "openai_endpoint" {
#   value = azurerm_cognitive_account.openai.endpoint
# }

# output "openai_primary_key" {
#   value     = azurerm_cognitive_account.openai.primary_access_key
#   sensitive = true
# }

# output "gpt_model_deployment_name" { 
#   value       = azurerm_cognitive_deployment.gpt_model.name
#   description = "The name of the GPT model deployment"
# }

# output "embeddings_deployment_name" {
#   value = azurerm_cognitive_deployment.embeddings.name
# }

# output "openai_resource_name" {
#   value = azurerm_cognitive_account.openai.name
# }
