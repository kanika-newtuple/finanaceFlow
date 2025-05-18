output "acr_id" {
  description = "The ID of the Azure Container Registry"
  value       = azurerm_container_registry.acr.id
}

output "acr_login_server" {
  description = "The login server URL of the Azure Container Registry"
  value       = azurerm_container_registry.acr.login_server
}

output "acr_admin_username" {
  description = "The admin username of the Azure Container Registry"
  value       = azurerm_container_registry.acr.admin_username
}

output "acr_admin_password" {
  description = "The admin password of the Azure Container Registry"
  value       = azurerm_container_registry.acr.admin_password
  sensitive   = true
}

output "dummy_image_name" {
  description = "The name of the dummy image"
  value       = "dummyimage"
}

output "dummy_image_tag" {
  description = "The tag of the dummy image"
  value       = var.dummy_image_tag
}

output "dummy_image_reference" {
  description = "The full reference to the dummy image"
  value       = "${azurerm_container_registry.acr.login_server}/dummyimage:${var.dummy_image_tag}"
}

output "acr_name" {
  description = "The name of the Azure Container Registry"
  value       = azurerm_container_registry.acr.name
}
