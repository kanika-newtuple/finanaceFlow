variable "prefix" {
  description = "Prefix for all resources"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "sku" {
  description = "The SKU name of the container registry"
  type        = string
  default     = "Standard"
}

variable "admin_enabled" {
  description = "Enables admin user for the container registry"
  type        = bool
  default     = true
}

variable "dummy_image_tag" {
  description = "Tag for the dummy image to be pushed to ACR"
  type        = string
  default     = "v1"
}

variable "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace for diagnostic settings"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# New variables for private endpoint configuration
variable "enable_private_endpoint" {
  description = "Enable private endpoint for ACR"
  type        = bool
  default     = false
}

variable "subnet_id" {
  description = "Subnet ID for private endpoint"
  type        = string
  default     = ""
}

variable "virtual_network_id" {
  description = "Virtual Network ID for DNS zone link"
  type        = string
  default     = ""
}

variable "public_network_access_enabled" {
  description = "Whether to enable public network access for the ACR"
  type        = bool
  default     = true
}

variable "aks_kubelet_identity_object_id" {
  description = "Object ID of the AKS kubelet identity"
  type        = string
  default     = ""
}
