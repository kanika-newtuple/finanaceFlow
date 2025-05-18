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
  description = "Name of the virtual network"
  type        = string
}

variable "subnet_address_prefix" {
  description = "Address prefix for AKS subnet"
  type        = string
  default     = "10.0.0.0/24"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
}

variable "vm_size" {
  description = "VM size for node pool"
  type        = string
  default     = "Standard_D2_v2"
}

variable "os_disk_size_gb" {
  description = "OS disk size for nodes"
  type        = number
  default     = 30
}

variable "min_node_count" {
  description = "Minimum node count"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum node count"
  type        = number
  default     = 3
}

variable "private_cluster_enabled" {
  description = "Enable private cluster"
  type        = bool
  default     = true
}

variable "network_plugin" {
  description = "Network plugin to use"
  type        = string
  default     = "azure"
}

variable "network_policy" {
  description = "Network policy to use"
  type        = string
  default     = "calico"
}

variable "load_balancer_sku" {
  description = "Load balancer SKU"
  type        = string
  default     = "standard"
}

variable "service_cidr" {
  description = "Service CIDR"
  type        = string
  default     = "10.1.0.0/16"
}

variable "dns_service_ip" {
  description = "DNS Service IP"
  type        = string
  default     = "10.1.0.10"
}

variable "docker_bridge_cidr" {
  description = "Docker bridge CIDR"
  type        = string
  default     = "172.17.0.1/16"
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  type        = string
}

variable "annotations_allowed" {
  description = "Annotations allowed for monitor metrics"
  type        = string
  default     = "app"
}

variable "labels_allowed" {
  description = "Labels allowed for monitor metrics"
  type        = string
  default     = "app"
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}

variable "acr_id" {
  description = "ID of the Azure Container Registry to attach to the AKS cluster"
  type        = string
  default     = ""
}

variable "private_lb_ip_address" {
  description = "Static private IP for AKS internal Load Balancer"
  type        = string
  default     = "10.0.0.10"  # Adjust based on your subnet
}
