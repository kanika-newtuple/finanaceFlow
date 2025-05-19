output "container_app_environment_id" {
  description = "ID of the Container App Environment"
  value       = azurerm_container_app_environment.container_env.id
}

output "container_app_environment_name" {
  description = "Name of the Container App Environment"
  value       = azurerm_container_app_environment.container_env.name
}

output "container_app_environment_subnet_id" {
  description = "ID of the subnet used by the Container App Environment"
  value       = azurerm_subnet.container_env_subnet.id
}

output "container_app_environment_static_ip" {
  description = "Static IP address of the Container App Environment"
  value       = azurerm_container_app_environment.container_env.static_ip_address
}

output "container_app_environment_default_domain" {
  description = "Default domain of the Container App Environment"
  value       = azurerm_container_app_environment.container_env.default_domain
}
