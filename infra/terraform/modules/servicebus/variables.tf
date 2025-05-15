variable "prefix" {
  description = "Prefix to be used for all resources"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "servicebus_sku" {
  description = "SKU for Service Bus namespace (Basic, Standard, Premium)"
  type        = string
  default     = "Standard"
}

variable "servicebus_capacity" {
  description = "Capacity for Service Bus namespace"
  type        = number
  default     = 1
}

variable "queues" {
  description = "List of Service Bus queues to create"
  type = list(object({
    name              = string
    max_size_mb       = number
    message_ttl       = string
    max_delivery_count = number
    lock_duration     = string
  }))
}

variable "virtual_network_name" {
  description = "Name of the virtual network"
  type        = string
  default     = ""
}

variable "virtual_network_id" {
  description = "ID of the virtual network"
  type        = string
  default     = ""
}

variable "subnet_address_prefix" {
  description = "Address prefix for the Service Bus subnet"
  type        = string
  default     = "10.0.3.0/24"
}

variable "create_private_endpoint" {
  description = "Whether to create private endpoint for Service Bus"
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace for diagnostic settings"
  type        = string
}

variable "tags" {
  description = "Tags to be applied to resources"
  type        = map(string)
  default     = {}
}
