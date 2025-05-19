variable "prefix" {
  description = "Prefix for all resources"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
}

variable "openai_location" {
  description = "Azure region for OpenAI service"
  type        = string
}

variable "openai_sku" {
  description = "SKU for OpenAI service"
  type        = string
  default     = "S0"
}

variable "virtual_network_name" {
  description = "Name of the virtual network"
  type        = string
}

variable "virtual_network_id" {
  description = "ID of the virtual network"
  type        = string
}
variable "secondary_virtual_network_id" {
  description = "ID of the virtual network"
  type        = string
}

variable "subnet_address_prefix" {
  description = "Address prefix for the OpenAI subnet"
  type        = string
  default     = "10.0.18.0/24"
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

variable "gpt_model_name" {
  description = "Name of the GPT model to deploy"
  type        = string
  default     = "gpt-4o"
}

variable "gpt_model_version" {
  description = "Version of the GPT model"
  type        = string
  default     = "2024-05-13"
}

variable "gpt_scale_type" {
  description = "Standard of the GPT model"
  type        = string
  default     = "GlobalStandard"
}

variable "gpt_model_capacity" {
  description = "Capacity for the GPT model"
  type        = number
  default     = 1
}

variable "embeddings_model_name" {
  description = "Name of the embeddings model to deploy"
  type        = string
  default     = "text-embedding-3-large"
}

variable "embeddings_model_version" {
  description = "Version of the embeddings model"
  type        = string
  default     = "1"
}

variable "embeddings_capacity" {
  description = "Capacity for the embeddings model"
  type        = number
  default     = 1
}

variable "openai_resource_suffix" {
  description = "A suffix to append to OpenAI resource names for uniqueness (e.g., 'primary', 'secondary', or a region like 'eastus')."
  type        = string
  default     = ""
}

variable "create_private_dns_zone" {
  description = "If true, this module instance will attempt to create the private DNS zone. Set to false if the zone is managed externally or by another instance."
  type        = bool
  default     = true
}

variable "suffix" {
  description = "The name of the private DNS zone to use or create. Defaults to 'privatelink.openai.azure.com'."
  type        = string
  default     = "secondary"
}

variable "private_dns_zone_resource_group_override" {
  description = "The resource group for the private DNS zone. If null, var.resource_group_name (the module's main resource group) is used."
  type        = string
  default     = null
}

variable "vnet_link_name_suffix" {
  description = "A suffix for the private DNS zone virtual network link resource name to ensure its uniqueness. Defaults to a value derived from openai_resource_suffix and virtual_network_id."
  type        = string
  default     = ""
}
