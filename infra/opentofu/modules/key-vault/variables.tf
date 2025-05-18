# modules/key-vault/variables.tf

variable "prefix" {
  description = "The prefix for all resource names"
  type        = string
}

variable "environment" {
  description = "The environment (dev, test, prod, etc.)"
  type        = string
}


variable "location" {
  description = "Azure location where resources will be deployed"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "tenant_id" {
  description = "Tenant ID for the Key Vault"
  type        = string
}

variable "soft_delete_retention_days" {
  description = "Soft delete retention period for Key Vault"
  type        = number
  default     = 7
}

variable "purge_protection_enabled" {
  description = "Enable purge protection on Key Vault"
  type        = bool
  default     = false
}

variable "sku_name" {
  description = "SKU name for the Key Vault (e.g., standard or premium)"
  type        = string
  default     = "standard"
}

variable "enable_rbac_authorization" {
  description = "Enable RBAC authorization for Key Vault"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}

variable "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace for diagnostics"
  type        = string
}

variable "admin_principal_id" {
  description = "Principal ID to assign Key Vault Administrator role"
  type        = string
}