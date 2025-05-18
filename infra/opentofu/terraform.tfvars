# Core Configuration
prefix      = "genaidocs"
environment = "uat"
location    = "East US"

# Azure Authentication
azure_subscription_id = "cb0f5d39-b859-40c4-a52e-5a22e7189743"
azure_tenant_id       = "19c7ef11-327f-423d-bb0e-826aa3304029"

# Service Bus Configuration
servicebus_sku            = "Premium"
servicebus_capacity       = 1
short_doc_queue_name      = "short-doc-queue"
long_doc_queue_name       = "long-doc-queue"
msbilling_queue_name       = "msbilling-queue"
enable_queue_partitioning = false
queue_max_size_mb         = 5120
queue_message_ttl         = "P14D"
max_delivery_count        = 1


storage_container_name = "blob"
storage_account_name= "genaidocsstorage"

# Document Processing Configuration
doc_processing_threshold       = 1
short_doc_processing_threshold = 8
long_doc_processing_threshold  = 8


# Kubernetes Configuration
kubernetes_version = "1.29"
node_count         = 4
min_node_count     = 2
max_node_count     = 4
vm_size            = "Standard_DS2_v2"
private_cluster    = true

# Cosmos DB for PostgreSQL Configuration
postgres_version        = "16" #14
postgres_admin_username = "citus"
postgres_admin_password = "G34cgrQiMRBcWVHXxSWhh2ZyMA4=" # Change before use
postgres_storage_mb     = 131072

# Azure Functions Configuration
function_sku                     = "P1v2"
enable_function_vnet_integration = true
backend_admin_user               = "uatadmin"
backend_admin_pw                 = "+CLB5P3OD6NY7C0FSuJHosATu4A="
gpt_scale_type                   = "Standard"

# Grafana & Prometheus Configuration
grafana_public_access    = true
grafana_admin_object_ids = ["16148a76-cc73-4961-a5a9-ad0624d250f3"] # Replace with actual Azure AD Object IDs
enable_prometheus_alerts = true

# Container App Job Configuration
doc_processor_image_version           = "v1"
doc_processor_job_parallelism         = 50
doc_processor_job_max_executions      = 8
doc_processor_job_scale_message_count = 5

# Monitoring Configuration
alert_email = "devops@pcrinsights.com"

# Jump Server Configuration
jumpbox_admin_username      = "adminuser"
jumpbox_ssh_public_key      = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCowuu/qjoDKjT/+QuYIU5K2jH5tSH8vaVxFbw0jUHS8Ngrk9iisUn0C8+NR3NnCyDdrI00l3jvvdFc5QX8qkYw9u7OgyZAUOjLAyrGDi49X/5pGKNFKcTr+jRjGCUexEgBwihpBH2bxZ1zeJy0SqISlBGEyoH97oJfOc/ydHlJGFnd3Mg9n5Ls/GF0I3Q95R0r4d2PQCtMUNa6k4lwD6Eh6wgRVP9Zou7HPdLj+0jNsprL8+UeztZbhOXDmjY7w5a4i1Ce2rm8nbCgNWAVOKKe6V7I+CPL0n/uZb6/qIXfwyXFW+mwGVu7FHGbHZIw13KEhaOuJHkmNSou3rIifXnG7rGnolEvh7Q5SFbG4vsD62OwG3Fxr3F6uoCtjPqHqI9AdP7mz2dRLGS9+Vnnud9OIANQBpcEJc2zbjAUQzr97e09cmGkuEV1b2PVZ+qAoClVuxvRCmRhd0yzLhNaIjHULULOWo9l8/YghlW6dDq/C9zJHMjZIrXObTKY9DFBcfU= PCR-NET+rmemane@PCR-RMemane"
jumpbox_ssh_public_key_path = "/Users/rahulkumar/Newtuple/Newtuple_repos/pcr/GENAIDocs/pcr_iac/terraform/genaisshvm.pub"
allowed_ssh_source_ips      = ["58.84.60.179"] # Replace with your IP address
jumpbox_vm_size             = "Standard_B2s_v2"


# APIM Configuration
# apim_publisher_name  = "GenAIDocs"
# apim_publisher_email = "devops@pcrinsights.com"
# apim_sku_name        = "Developer_1"

# SQL Server Configuration
sql_admin_username       = "dbaadmin"
sql_admin_password       = "Pcr@8888" # Change before use
sql_database_sku         = "S3"
sql_database_max_size_gb = 32 # Reduced from 10GB to 2GB for Basic tier compatibility

# Azure OpenAI Configuration
openai_location     = "East US"
openai_sku          = "S0"
openai_model_capacity = 100
embeddings_capacity = 1
openai_model = "gpt-4o"
embeddings_model_name = "text-embedding-3-large"

secondary_location="Sweden Central"
secondary_vnet_address_space="10.3.0.0/16"
secondary_openai_subnet_address_prefix="10.3.0.0/24"
secondary_openai_location="Sweden Central"
secondary_openai_sku="S0"
secondary_openai_model="gpt-4.1"
secondary_openai_model_capacity=100
secondary_embeddings_capacity=1


# Vnet
vnet_address_space = "10.0.0.0/16"

# Network address prefixes

aks_subnet_address_prefix              = "10.0.32.0/20"
function_subnet_address_prefix         = "10.0.2.0/24"
servicebus_address_prefix              = "10.0.1.0/24"
acr_address_prefix                     = "10.0.5.0/24"
postgres_subnet_address_prefix         = "10.0.6.0/24"
container_app_subnet_address_prefix    = "10.0.7.0/24"
sql_subnet_address_prefix              = "10.0.8.0/24"
container_app_pe_subnet_address_prefix = "10.0.9.0/24"
openai_subnet_address_prefix           = "10.0.50.0/24"
storage_subnet_address_prefix          = "10.0.51.0/24"
subnet_pe_address_prefix = "10.0.4.0/24"

aks_private_lb_ip_address = "10.0.32.1"

# AKS network configuration
aks_service_cidr       = "10.1.0.0/16"
aks_dns_service_ip     = "10.1.0.10"
aks_docker_bridge_cidr = "172.17.0.1/16"



# Tags
tags = {
  tag1name      = "GenAIProject"
  tag2name      = "GenAIUAT"
  CostCenter    = "GenAIProject"
  CostSubCenter = "GenAIUAT"
  Project       = "GENAIDocs"
  Environment   = "User Acceptance Testing"
  ManagedBy     = "Terraform"
  Team          = "GenAI"
}
