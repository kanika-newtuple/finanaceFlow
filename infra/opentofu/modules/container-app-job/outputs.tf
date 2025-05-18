output "job_id" {
  description = "ID of the container app job"
  value       = azurerm_container_app_job.job.id
}

output "job_name" {
  description = "Name of the container app job"
  value       = azurerm_container_app_job.job.name
}

output "job_identity" {
  description = "Identity of the container app job if enabled"
  value       = try(azurerm_container_app_job.job.identity, null)
}
