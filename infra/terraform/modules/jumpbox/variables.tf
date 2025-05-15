variable "prefix" {
  description = "The prefix used for all resources"
  type        = string
}

variable "environment" {
  description = "The environment (dev, test, prod)"
  type        = string
}

variable "location" {
  description = "The Azure region where resources will be created"
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

variable "jumpbox_subnet_cidr" {
  description = "The CIDR block for the jumpbox subnet"
  type        = string
  default     = "10.0.17.0/24"
}

variable "allowed_ssh_source_ips" {
  description = "List of source IPs allowed to SSH to the jumpbox"
  type        = list(string)
}

variable "jumpbox_vm_size" {
  description = "The size of the jumpbox VM"
  type        = string
  default     = "Standard_B2s"
}

variable "jumpbox_admin_username" {
  description = "The admin username for the jumpbox VM"
  type        = string
}

variable "jumpbox_ssh_public_key" {
  description = "The public SSH key for the jumpbox VM"
  type        = string
}

variable "jumpbox_setup_script_path" {
  description = "Path to the setup script for the jumpbox"
  type        = string
}

variable "tenant_id" {
  description = "The Azure tenant ID"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
