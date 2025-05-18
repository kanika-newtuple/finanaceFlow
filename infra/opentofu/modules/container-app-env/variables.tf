variable "prefix" {
  description = "Prefix for all resources"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "location" {
  description = "Azure region"
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
  description = "Address prefix for the container app environment subnet"
  type        = string
}

variable "pe_subnet_address_prefix" {
  description = "The address prefix for the private endpoint subnet"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  type        = string
}

variable "workload_profiles" {
  description = "List of workload profiles for the Container App Environment"
  type = list(object({
    name                  = string
    workload_profile_type = string
    minimum_count         = optional(number)
    maximum_count         = optional(number)
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
