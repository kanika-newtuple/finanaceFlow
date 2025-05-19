output "function_storage_name" {
  description = "The name of the storage account for Azure Functions"
  value       = azurerm_storage_account.function_storage.name
}

output "function_storage_id" {
  description = "The ID of the storage account for Azure Functions"
  value       = azurerm_storage_account.function_storage.id
}

output "function_plan_id" {
  description = "The ID of the App Service Plan for Azure Functions"
  value       = azurerm_service_plan.function_plan.id
}

output "document_handler_id" {
  description = "The ID of the Document Handler Function App"
  value       = azurerm_linux_function_app.document_handler.id
}

output "file_processor_id" {
  description = "The ID of the File Processor Function App"
  value       = azurerm_linux_function_app.file_processor.id
}

output "document_handler_default_hostname" {
  description = "The default hostname of the Document Handler Function App"
  value       = azurerm_linux_function_app.document_handler.default_hostname
}

output "file_processor_default_hostname" {
  description = "The default hostname of the File Processor Function App"
  value       = azurerm_linux_function_app.file_processor.default_hostname
}

output "document_handler_principal_id" {
  description = "The principal ID of the Document Handler Function App's managed identity"
  value       = azurerm_linux_function_app.document_handler.identity[0].principal_id
}

output "file_processor_principal_id" {
  description = "The principal ID of the File Processor Function App's managed identity"
  value       = azurerm_linux_function_app.file_processor.identity[0].principal_id
}

output "function_subnet_id" {
  description = "The ID of the subnet for Azure Functions"
  value       = azurerm_subnet.function_subnet.id
}
