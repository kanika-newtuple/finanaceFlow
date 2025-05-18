variable "prefix" {
  description = "Prefix for all resources"
  type        = string
}

variable "environment" {
  description = "Environment (dev, test, prod)"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "virtual_network_name" {
  description = "Virtual network name"
  type        = string
}

variable "virtual_network_id" {
  description = "Virtual network ID"
  type        = string
}

variable "subnet_address_prefix" {
  description = "Address prefix for the function subnet"
  type        = string
}
variable "subnet_pe_address_prefix" {
  description = "Address prefix for the pe function subnet"
  type        = string
}

variable "app_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  type        = string
}

variable "key_vault_uri" {
  description = "Key Vault URI"
  type        = string
}

variable "servicebus_connection_string" {
  description = "Service Bus connection string"
  type        = string
  sensitive   = true
}

variable "short_doc_queue_name" {
  description = "Short document queue name"
  type        = string
}

variable "long_doc_queue_name" {
  description = "Long document queue name"
  type        = string
}

variable "storage_account_connection_string" {
  description = "Storage account connection string"
  type        = string
  sensitive   = true
}

variable "backend_admin_user" {
  description = "Backend admin username"
  type        = string
}

variable "backend_admin_pw" {
  description = "Backend admin password"
  type        = string
  sensitive   = true
}

variable "doc_processing_threshold" {
  description = "Document processing threshold"
  type        = number
}

variable "postgres_admin_password" {
  description = "PostgreSQL admin password"
  type        = string
  sensitive   = true
}

variable "postgres_server_name" {
  description = "PostgreSQL server name"
  type        = string
}

variable "documents_container_name" {
  description = "Documents container name"
  type        = string
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = false
}

variable "os_type" {
  description = "OS type for the function app"
  type        = string
  default     = "Linux"
}

variable "python_version" {
  description = "Python version for the function app"
  type        = string
  default     = "3.10"
}

variable "service_plan_sku" {
  description = "Service plan SKU"
  type        = string
  default     = "B1"
}

variable "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace for diagnostic settings"
  type        = string
}

variable "tags" {
  description = "Tags for the resources"
  type        = map(string)
  default     = {}
}
