variable "prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string
}

variable "location" {
  description = "Azure region to deploy resources"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "subnet_address_prefix" {
  description = "The address prefix for the Application Gateway subnet"
  type        = string
}

variable "virtual_network_name" {
  description = "Name of the virtual network"
  type        = string
}

variable "virtual_network_id" {
  description = "ID of the virtual network"
  type        = string
}

variable "private_ip_address" {
  description = "The private IP address for the Application Gateway"
  type        = string
}

variable "sku_name" {
  description = "The SKU name of the Application Gateway"
  type        = string
  default     = "WAF_v2"
}

variable "sku_tier" {
  description = "The SKU tier of the Application Gateway"
  type        = string
  default     = "WAF_v2"
}

variable "capacity" {
  description = "The capacity (instance count) of the Application Gateway"
  type        = number
  default     = 2
}

variable "waf_mode" {
  description = "The Web Application Firewall mode (Detection or Prevention)"
  type        = string
  default     = "Detection"
}

variable "priority" {
  description = "The priority of the routing rule"
  type        = number
  default     = 100
}

variable "create_private_dns" {
  description = "Whether to create the private DNS zone"
  type        = bool
  default     = true
}

variable "bot_service_private_ip" {
  description = "The private IP address for the bot service DNS record"
  type        = string
  default     = ""
}

variable "dns_name" {
  description = "The DNS name for the Application Gateway"
  default     = "bot"
  type        = string
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