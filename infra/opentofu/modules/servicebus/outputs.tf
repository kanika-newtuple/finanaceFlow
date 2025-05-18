output "namespace_id" {
  description = "ID of the Service Bus namespace"
  value       = azurerm_servicebus_namespace.sb_namespace.id
}

output "namespace_name" {
  description = "Name of the Service Bus namespace"
  value       = azurerm_servicebus_namespace.sb_namespace.name
}

output "default_primary_connection_string" {
  description = "Primary connection string for the Service Bus namespace"
  value       = azurerm_servicebus_namespace.sb_namespace.default_primary_connection_string
  sensitive   = true
}

output "queues" {
  description = "Map of queues created"
  value       = { for name, queue in azurerm_servicebus_queue.queues : name => {
    id   = queue.id
    name = queue.name
  }}
}

output "private_endpoint_ip" {
  description = "Private IP address of the Service Bus private endpoint"
  value       = var.create_private_endpoint ? azurerm_private_endpoint.servicebus_endpoint[0].private_service_connection[0].private_ip_address : null
}

output "private_dns_zone_id" {
  description = "ID of the private DNS zone"
  value       = var.create_private_endpoint ? azurerm_private_dns_zone.servicebus_dns[0].id : null
}
