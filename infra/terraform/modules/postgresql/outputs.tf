output "postgres_id" {
  description = "The ID of the PostgreSQL Cluster"
  value       = azurerm_cosmosdb_postgresql_cluster.postgres.id
}

output "postgres_name" {
  description = "The name of the PostgreSQL Cluster"
  value       = azurerm_cosmosdb_postgresql_cluster.postgres.name
}


output "postgres_endpoint" {
  description = "The private endpoint connection"
  value       = azurerm_private_endpoint.postgres_endpoint.private_service_connection[0].private_ip_address
}
