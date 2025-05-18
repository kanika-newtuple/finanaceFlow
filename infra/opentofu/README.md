# OpenTofu Configuration

This directory contains OpenTofu configurations to set up the Azure infrastructure required for the document processing service. 

> **Note**: This project has migrated from Terraform to OpenTofu. OpenTofu is a drop-in replacement that maintains compatibility with Terraform configurations while remaining open source.

## Prerequisites

- [OpenTofu](https://opentofu.org/downloads) (v1.6.0 or newer)
- Azure CLI installed and logged in (`az login`)
- Proper Azure permissions to create resources

## Configuration

1. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` and provide your specific values:
   - Azure subscription and tenant IDs
   - Environment name (dev, test, prod)
   - Service Bus and queue configuration
   - Fernet encryption key
   - Kubernetes cluster configuration
   - PostgreSQL database settings
   - Grafana and Prometheus settings
   - Monitoring parameters

## Usage

Initialize OpenTofu:
```bash
tofu init
```

Review the execution plan:
```bash
tofu plan
```

Apply the configuration:
```bash
tofu apply
```

## Resources Created

### Core Infrastructure
- Resource Group
- Virtual Network with subnets

### Messaging
- Service Bus Namespace
- Service Bus Queues (for short and long documents)

### Storage
- Storage Account with container for unstructured documents
- Azure Cosmos DB for PostgreSQL Cluster with database

### Compute
- Azure Kubernetes Service (AKS) cluster
- Azure Container Registry (ACR)
- Azure Functions (document-handler and file-processor)

### Security
- Azure Key Vault with secrets
- PostgreSQL Firewall Rules

### Monitoring
- Application Insights
- Log Analytics Workspace
- Azure Monitor Alert Rules
- Azure Managed Grafana
- Azure Managed Prometheus
- Prometheus Alert Rules for AKS

## Outputs

After applying the configuration, you'll get important outputs including:
- Service Bus connection string
- Queue names
- Storage account access keys
- Application Insights instrumentation key
- Key Vault URI
- Container Registry login details
- Kubernetes cluster credentials
- PostgreSQL connection strings
- Grafana endpoint
- Prometheus workspace details

These values can be used to configure your application's environment variables.

## Azure Cosmos DB for PostgreSQL Cluster Configuration

The infrastructure uses Azure Cosmos DB for PostgreSQL, which provides:

- A distributed PostgreSQL database built on Citus
- Horizontal scaling with sharding
- Enterprise-grade high availability
- Advanced security features
- Scalable compute and storage resources

Key PostgreSQL configuration options:

- **Node Configuration**: The default setup includes a coordinator node and worker nodes for distributed processing
- **Performance Tier**: Configured with vCore settings for both coordinator and worker nodes
- **Storage**: Default configuration includes 32GB of storage per node
- **Scaling**: Easily scale out by adding more worker nodes or scaling up by increasing vCores
- **Security**: Private endpoint integration is configured for secure access from the AKS cluster

Cosmos DB for PostgreSQL metrics are monitored through Azure Monitor and can be visualized in Grafana using the provided PostgreSQL dashboard.

## PostgreSQL Connection

To connect to the PostgreSQL database:

```bash
psql "host=$(tofu output -raw postgres_server_fqdn) dbname=$(tofu output -raw postgres_database_name) user=$(tofu output -raw postgres_admin_username) password=$(tofu output -raw postgres_admin_password) port=5432 sslmode=require"
```

## Accessing Grafana

1. After deployment, access the Grafana portal using the endpoint provided in the OpenTofu output:
   ```bash
   echo "Grafana Endpoint: $(tofu output -raw grafana_endpoint)"
   ```

2. Log in with your Azure AD credentials (users in the `grafana_admin_object_ids` list will have admin privileges)

3. Grafana is pre-configured with the Prometheus data source from the Azure Managed Prometheus instance

## Prometheus Alert Rules

Pre-configured alert rules include:

- **NodeCPUUsage**: Alerts when node CPU usage is above 80% for 5 minutes
- **NodeMemoryUsage**: Alerts when node memory usage is above 80% for 5 minutes
- **NodeDiskPressure**: Alerts when a node is experiencing disk pressure

These alerts will be sent to the configured action group (email notification).

## Integration with AKS

To configure your AKS cluster to pull images from your ACR:

```bash
az aks update -n $(tofu output -raw kubernetes_cluster_name) \
              -g $(tofu output -raw resource_group_name) \
              --attach-acr $(tofu output -raw container_registry_name)
```

## Custom Grafana Dashboards

To create custom dashboards for your applications, log into Grafana and:

1. Navigate to "Create" > "Import"
2. Import standard dashboards using their IDs:
   - Kubernetes Cluster: 15661
   - Kubernetes Nodes: 15664
   - Kubernetes Workloads: 15758
   - PostgreSQL: 9628

Or create custom dashboards using PromQL queries.

## Azure Functions

The infrastructure includes two Azure Functions to manage document processing workflows:

1. **GenAI-document-handler**: Manages document ingestion and coordinates the processing workflow
   - Triggers: HTTP and Service Bus Queue
   - Functions:
     - Document upload via HTTP
     - Queue message processing
     - Task status management

2. **GenAI-file-processor**: Performs the actual document processing using AI capabilities
   - Triggers: Blob storage and Service Bus Queue
   - Functions:
     - Document content extraction
     - AI-powered content analysis
     - Metadata generation

### Function Configuration

Both functions are deployed with:
- Python 3.10 runtime
- Premium service plan (P1v2) for reliable performance
- System-assigned managed identities for secure access to Azure services
- Application Insights integration for monitoring
- Key Vault integration for secure secrets management

### Local Development

To run and debug functions locally:

1. Install the Azure Functions Core Tools:
   ```bash
   npm install -g azure-functions-core-tools@4
   ```

2. Clone the function code repositories:
   ```bash
   git clone https://your-repo-url/GenAI-document-handler.git
   git clone https://your-repo-url/GenAI-file-processor.git
   ```

3. Create local settings files with appropriate values:
   ```bash
   cp local.settings.example.json local.settings.json
   # Edit local.settings.json with your development values
   ```

4. Run the function locally:
   ```bash
   func start
   ```

### Deployment

Functions are automatically deployed using OpenTofu, but you can also deploy manually:

```bash
func azure functionapp publish GenAI-document-handler --python
func azure functionapp publish GenAI-file-processor --python
```

## Azure Container App Job

The infrastructure includes an Azure Container App Job for document processing:

### Doc Processor Job

This Container App Job is designed for processing documents from a queue:

- **High-performance configuration**: 4 vCPU cores and 8GB memory per replica
- **Scalable processing**: Supports up to 50 parallel replicas for efficient document processing
- **Queue-based scaling**: Automatically scales based on Azure Service Bus queue depth
- **Configurable parameters**: Execution limits, job timeouts, and scaling rules can be adjusted in terraform.tfvars (OpenTofu uses the same file format)

You can manually trigger a new job execution using the Azure CLI:

```bash
az containerapp job start \
  --name $(tofu output -raw doc_processor_job_name) \
  --resource-group $(tofu output -raw resource_group_name)
```

### Integration with Service Bus and Storage

The Container App Job integrates with:
- Azure Service Bus queue for receiving document processing tasks
- Azure Storage for accessing document content
- Azure PostgreSQL for storing processing results

## Clean Up

To destroy all created resources:
```bash
tofu destroy
```

## Recommended Next Steps

1. Set up CI/CD pipelines to deploy your applications to AKS
2. Configure network security rules and private endpoints for PostgreSQL
3. Implement backup and disaster recovery for critical data
4. Create custom Grafana dashboards for your specific applications
5. Set up additional monitoring and alerting based on your requirements