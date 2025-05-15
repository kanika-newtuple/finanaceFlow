output "openai_id" {
  description = "ID of the Azure OpenAI service"
  value       = azurerm_cognitive_account.openai.id
}

output "openai_endpoint" {
  description = "Endpoint of the Azure OpenAI service"
  value       = azurerm_cognitive_account.openai.endpoint
}

output "openai_primary_key" {
  description = "Primary key of the Azure OpenAI service"
  value       = azurerm_cognitive_account.openai.primary_access_key
  sensitive   = true
}

output "openai_name" {
  description = "Name of the Azure OpenAI service"
  value       = azurerm_cognitive_account.openai.name
}

# output "gpt_model_name" {
#   description = "Name of the deployed GPT model"
#   value       = azurerm_cognitive_deployment.gpt_model.name
# }

output "embeddings_model_name" {
  description = "Name of the deployed embeddings model"
  value       = azurerm_cognitive_deployment.embeddings.name
}

output "subnet_id" {
  description = "ID of the OpenAI subnet"
  value       = azurerm_subnet.openai_subnet.id
}
