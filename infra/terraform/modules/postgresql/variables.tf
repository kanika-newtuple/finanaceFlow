variable "prefix" {
  description = "The prefix for all resource names"
  type        = string
}

variable "environment" {
  description = "The environment (dev, test, prod, etc.)"
  type        = string
}

variable "location" {
  description = "The Azure location where resources will be created"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "virtual_network_name" {
  description = "The name of the virtual network"
  type        = string
}

variable "virtual_network_id" {
  description = "The ID of the virtual network"
  type        = string
}

variable "subnet_address_prefix" {
  description = "The address prefix for the PostgreSQL subnet"
  type        = string
}

variable "postgres_admin_password" {
  description = "The PostgreSQL admin password"
  type        = string
  sensitive   = true
}

variable "storage_mb" {
  description = "The storage quota for the coordinator in MB"
  type        = number
}

variable "vcore_count" {
  description = "The vCore count for the coordinator"
  type        = number
  default     = 2
}

variable "node_count" {
  description = "The number of nodes in the PostgreSQL cluster (0 for single coordinator mode)"
  type        = number
  default     = 0
}

variable "postgres_version" {
  description = "The PostgreSQL version"
  type        = string
  default     = "16"
}

variable "log_analytics_workspace_id" {
  description = "ID of the Log Analytics Workspace for diagnostic settings"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
