variable "prefix" {
  description = "Prefix to use for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "storage_subnet_address_prefix" {
  description = "The subnet of the storage account"
  type        = string
  default = "10.0.7.0/24"
}

variable "location" {
  description = "The Azure region where resources should be created"
  type        = string
}

variable "account_tier" {
  description = "Defines the Tier to use for this storage account"
  type        = string
  default     = "Standard"
}

variable "account_replication_type" {
  description = "Defines the type of replication to use for this storage account"
  type        = string
  default     = "LRS"
}

variable "container_name" {
  description = "Name of the storage container"
  type        = string
  default     = "unstructured"
}

variable "container_access_type" {
  description = "The Access Level configured for this Container"
  type        = string
  default     = "private"
}

variable "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace for diagnostic settings"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "vnet" {
  description = "Virtual network object to use for storage subnet"
  type = object({
    name = string
    id   = string
  })
}
