variable "prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "genaidocs"
}

variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string
  default     = "dev"

}

variable "storage_account_name" {
  description = "Name of the storage account"
  type        = string
  default     = "genaidocsstorage"
  
}

variable "location" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "East US"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "GENAIDocs"
    Environment = "Development"
    ManagedBy   = "Terraform"
  }
}

variable "azure_subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "azure_tenant_id" {
  description = "Azure Tenant ID"
  type        = string
}

variable "servicebus_sku" {
  description = "SKU for Service Bus Namespace (Basic, Standard, Premium)"
  type        = string
  default     = "Standard"
}

variable "servicebus_capacity" {
  description = "Capacity for Service Bus Namespace (1, 2, 4)"
  type        = number
  default     = 1
}

variable "short_doc_queue_name" {
  description = "Name of the short document processing queue"
  type        = string
  default     = "short-doc-queue"
}

variable "long_doc_queue_name" {
  description = "Name of the long document processing queue"
  type        = string
  default     = "long-doc-queue"
}

variable "msbilling_queue_name" {
  description = "Name of the msbilling queue"
  type        = string
  default     = "msbilling-queue"
}



variable "enable_queue_partitioning" {
  description = "Enable partitioning for Service Bus queues"
  type        = bool
  default     = true
}

variable "queue_max_size_mb" {
  description = "Maximum size of queue in megabytes"
  type        = number
  default     = 1024
}

variable "queue_message_ttl" {
  description = "Default message time-to-live in seconds"
  type        = string
  default     = "P14D" # 14 days in ISO 8601 format
}

variable "max_delivery_count" {
  description = "Maximum delivery count for messages"
  type        = number
  default     = 10
}

variable "doc_processing_threshold" {
  description = "Maximum number of documents to process in one batch"
  type        = number
  default     = 10
}


variable "storage_container_name" {
  description = "Name of the storage container for document processing"
  type        = string
  default     = "blob"

}


variable "backend_admin_user" {
  description = "Backend user (sensitive)"
  type        = string
  sensitive   = true
}

variable "backend_admin_pw" {
  description = "Backend user pw (sensitive)"
  type        = string
  sensitive   = true
}

# Update PostgreSQL variables
variable "postgres_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "11"
}

variable "postgres_admin_username" {
  description = "PostgreSQL administrator username"
  type        = string
  default     = "psqladmin"
}

variable "postgres_admin_password" {
  description = "PostgreSQL administrator password"
  type        = string
  sensitive   = true
}

variable "postgres_storage_mb" {
  description = "PostgreSQL storage in MB"
  type        = number
  default     = 32768 # 32GB
}

variable "postgres_sku" {
  description = "PostgreSQL SKU name"
  type        = string
  default     = "GP_Gen5_4" # General Purpose tier
}

variable "postgres_backup_retention_days" {
  description = "PostgreSQL backup retention days"
  type        = number
  default     = 7
}

variable "postgres_geo_redundant_backup" {
  description = "Enable geo-redundant backups"
  type        = bool
  default     = false
}

variable "kubernetes_version" {
  description = "Kubernetes version to use for AKS"
  type        = string
  default     = "1.26.3"
}

variable "node_count" {
  description = "Initial number of nodes in AKS cluster"
  type        = number
  default     = 2
}

variable "min_node_count" {
  description = "Minimum number of nodes for auto-scaling"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum number of nodes for auto-scaling"
  type        = number
  default     = 5
}

variable "private_cluster" {
  description = "Enable private cluster for AKS"
  type        = bool
  default     = true

}

variable "vm_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_DS2_v2"
}

variable "jumpbox_vm_size" {
  description = "VM size for jumpbox"
  type        = string
  default     = "Standard_E104i_v5"
}

# Azure Functions variables
variable "function_sku" {
  description = "SKU for Azure Functions App Service Plan"
  type        = string
  default     = "P1v2" # Premium plan with vNet integration support
}

variable "enable_function_vnet_integration" {
  description = "Enable VNet integration for Functions"
  type        = bool
  default     = true
}

variable "subnet_pe_address_prefix" {
  description = "Enable VNet integration for Functions"
  type        = string
}

variable "openai_api_key" {
  description = "OpenAI API key for document processing"
  type        = string
  sensitive   = true
  default     = ""
}

variable "openai_model" {
  description = "OpenAI model to use for document processing"
  type        = string
  default     = "gpt-4o"
}
variable "embeddings_model_name" {
  description = "Model name for embeddings"
  type        = string
  default     = "text-embedding-3-large"
  
}



variable "alert_email" {
  description = "Email address for critical alerts"
  type        = string
  default     = "admin@example.com"
}

# Grafana & Prometheus variables
variable "grafana_public_access" {
  description = "Enable public access to Grafana dashboard"
  type        = bool
  default     = false
}

variable "grafana_admin_object_ids" {
  description = "List of Azure AD Object IDs that should have Grafana Admin role"
  type        = list(string)
  default     = []
}

variable "grafana_major_version" {
  description = "Grafana major version to deploy"
  type        = string
  default     = "10"
}

variable "enable_prometheus_alerts" {
  description = "Enable Prometheus alert rules"
  type        = bool
  default     = true
}

# Container App Job variables
variable "doc_processor_image_version" {
  description = "Docker image version for doc-processor container app job"
  type        = string
  default     = "latest"
}

variable "doc_processor_job_parallelism" {
  description = "Maximum number of parallel replicas for doc-processor job"
  type        = number
  default     = 50
}

variable "doc_processor_job_max_executions" {
  description = "Maximum number of executions for doc-processor job"
  type        = number
  default     = 8
}

variable "doc_processor_job_scale_message_count" {
  description = "Message count for scaling the doc-processor job"
  type        = number
  default     = 5
}

variable "doc_processor_endpoint_url" {
  description = "Endpoint URL for triggering the doc-processor job"
  type        = string
  default     = ""
}

# APIM Configuration
variable "apim_publisher_name" {
  description = "Publisher name for API Management"
  type        = string
  default     = "GenAIDocs"
}

variable "apim_publisher_email" {
  description = "Publisher email for API Management"
  type        = string
  default     = "admin@example.com"
}

variable "apim_sku_name" {
  description = "SKU for API Management (Developer, Basic, Standard, Premium)"
  type        = string
  default     = "Developer_1"
}

# Jumpbox Configuration
variable "jumpbox_admin_username" {
  description = "Admin username for jumpbox VM"
  type        = string
  default     = "adminuser"
}

variable "jumpbox_ssh_public_key" {
  description = "SSH public key for jumpbox VM authentication"
  type        = string
}

variable "jumpbox_ssh_public_key_path" {
  description = "Path to SSH public key file for jumpbox VM"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "allowed_ssh_source_ips" {
  description = "List of source IP addresses allowed to SSH to jumpbox"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# SQL Server Configuration
variable "sql_admin_username" {
  description = "SQL Server administrator username"
  type        = string
  default     = "sqladmin"
}

variable "sql_admin_password" {
  description = "SQL Server administrator password"
  type        = string
  sensitive   = true
}

variable "sql_database_sku" {
  description = "SKU for SQL Database"
  type        = string
  default     = "S2"
}

variable "sql_database_max_size_gb" {
  description = "Maximum size of SQL Database in GB"
  type        = number
  default     = 32
}

# Azure OpenAI Configuration
variable "openai_location" {
  description = "Location for Azure OpenAI service"
  type        = string
  default     = "East US"
}
variable "gpt_scale_type" {
  description = "Standard of the GPT model"
  type        = string
  default     = "Standard"
}
variable "openai_sku" {
  description = "SKU for Azure OpenAI service"
  type        = string
  default     = "S0"
}
variable "vnet_address_space" {
  description = "Address space for vnet"
  type        = string
  default     = "10.0.0.0/16"
}
variable "servicebus_address_prefix" {
  description = "Address space for vnet"
  type        = string
  default     = "10.0.3.0/24"
}

variable "acr_address_prefix" {
  description = "Address space for acr"
  type        = string
  default     = "10.0.5.0/24"
}

variable "openai_model_capacity" {
  description = "Capacity for GPT-4o deployment"
  type        = number
  default     = 1
}

variable "embeddings_capacity" {
  description = "Capacity for embeddings deployment"
  type        = number
  default     = 1
}

variable "short_doc_processing_threshold" {
  description = "Max msgs in short doc queue to trigger processing"
  type        = number
  default     = 8
}

variable "long_doc_processing_threshold" {
  description = "Max msgs in long doc queue to trigger processing"
  type        = number
  default     = 1
}

# AKS Networking
variable "aks_subnet_address_prefix" {
  description = "Address prefix for AKS subnet"
  type        = string
  default     = "10.0.0.0/24"
}
variable "aks_private_lb_ip_address" {
  description = "Address prefix for AKS LB"
  type        = string
  default     = "10.0.32.10"
}

variable "aks_service_cidr" {
  description = "Kubernetes service CIDR"
  type        = string
  default     = "10.1.0.0/16"
}

variable "aks_dns_service_ip" {
  description = "Kubernetes DNS service IP"
  type        = string
  default     = "10.1.0.10"
}

variable "aks_docker_bridge_cidr" {
  description = "Docker bridge CIDR"
  type        = string
  default     = "172.17.0.1/16"
}

# Container App Environment Networking
variable "container_app_subnet_address_prefix" {
  description = "Address prefix for Container App Environment subnet"
  type        = string
  default     = "10.0.7.0/24"
}

variable "container_app_pe_subnet_address_prefix" {
  description = "Address prefix for Container App Environment private endpoints subnet"
  type        = string
  default     = "10.0.9.0/24"
}

# PostgreSQL Networking
variable "postgres_subnet_address_prefix" {
  description = "Address prefix for PostgreSQL subnet"
  type        = string
  default     = "10.0.6.0/24"
}

# Azure Functions Networking
variable "function_subnet_address_prefix" {
  description = "Address prefix for Azure Functions subnet"
  type        = string
  default     = "10.0.2.0/24"
}

# SQL Server Networking
variable "sql_subnet_address_prefix" {
  description = "Address prefix for SQL Server subnet"
  type        = string
  default     = "10.0.8.0/24"
}

# Azure OpenAI Networking
variable "openai_subnet_address_prefix" {
  description = "Address prefix for Azure OpenAI subnet"
  type        = string
  default     = "10.0.18.0/24"
}

# Storage Account Networking
variable "storage_subnet_address_prefix" {
  description = "Address prefix for Storage Account subnet"
  type        = string
  default     = "10.0.7.0/24"
}

variable "appgw_subnet_address_prefix" {
  description = "The address prefix for the Application Gateway subnet"
  type        = string
  default     = "10.0.3.0/24"
}

variable "appgw_private_ip_address" {
  description = "The private IP address for the Application Gateway"
  type        = string
  default     = "10.0.3.7"
}

variable "bot_service_private_ip" {
  description = "The private IP address for the bot service DNS record"
  type        = string
  default     = "10.0.31.4"
}

variable "secondary_location" {
  description = "Azure region for the secondary OpenAI service and VNet."
  type        = string
  default     = "West US 2" # Choose an appropriate secondary region
}

variable "secondary_vnet_address_space" {
  description = "Address space for the secondary VNet."
  type        = string
  default     = "10.2.0.0/16" # Ensure this doesn't overlap with existing VNets
}

variable "secondary_openai_subnet_address_prefix" {
  description = "Address prefix for the Azure OpenAI subnet in the secondary VNet."
  type        = string
  default     = "10.2.0.0/24" # Subnet within the secondary_vnet_address_space
}

variable "secondary_openai_location" {
  description = "Azure region for the secondary OpenAI service deployment (must be an OpenAI supported region)."
  type        = string
  default     = "West US" # Choose an appropriate OpenAI supported region
}

variable "secondary_openai_model" {
  description = "OpenAI model to use for the secondary OpenAI service."
  type        = string
  default     = "gpt-4.1"
  
}

variable "secondary_openai_sku" {
  description = "SKU for the secondary OpenAI service."
  type        = string
  default     = "S0"
}

variable "secondary_openai_model_capacity" {
  description = "Capacity for GPT-4o deployment in the secondary OpenAI service."
  type        = number
  default     = 10 # Adjust as needed
}

variable "secondary_embeddings_capacity" {
  description = "Capacity for embeddings deployment in the secondary OpenAI service."
  type        = number
  default     = 1 # Adjust as needed
}

variable "secondary_gpt_scale_type" {
  description = "Scale type for the GPT model in the secondary OpenAI service."
  type        = string
  default     = "GlobalStandard"
}
