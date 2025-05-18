variable "environment" {
  description = "Environment name"
  type        = string
}

variable "job_name" {
  description = "Name of the job"
  type        = string
}

variable "container_app_environment_id" {
  description = "ID of the Container App Environment"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure location"
  type        = string
}

variable "replica_timeout_in_seconds" {
  description = "Timeout for replicas in seconds"
  type        = number
  default     = 3600
}

variable "replica_retry_limit" {
  description = "Retry limit for replicas"
  type        = number
  default     = 1
}

variable "parallelism" {
  description = "Maximum number of replicas that can run in parallel"
  type        = number
  default     = 50
}

variable "replica_completion_count" {
  description = "Number of replicas that need to complete for the job to be considered done"
  type        = number
  default     = 1
}

variable "min_executions" {
  description = "Minimum number of executions"
  type        = number
  default     = 0
}

variable "max_executions" {
  description = "Maximum number of executions"
  type        = number
  default     = 8
}

variable "polling_interval_in_seconds" {
  description = "Polling interval in seconds"
  type        = number
  default     = 60
}

variable "servicebus_namespace_name" {
  description = "Name of the Service Bus namespace"
  type        = string
}

variable "queue_name" {
  description = "Name of the queue to monitor"
  type        = string
}

variable "message_count_threshold" {
  description = "Message count threshold for scaling"
  type        = number
}

variable "servicebus_connection_string" {
  description = "Service Bus connection string"
  type        = string
  sensitive   = true
}

variable "acr_login_server" {
  description = "ACR login server"
  type        = string
}

variable "acr_username" {
  description = "ACR username"
  type        = string
}

variable "acr_password" {
  description = "ACR password"
  type        = string
  sensitive   = true
}

variable "container_name" {
  description = "Container name"
  type        = string
  default     = "processor"
}

variable "image_name" {
  description = "Docker image name"
  type        = string
}

variable "image_version" {
  description = "Docker image version"
  type        = string
}

variable "cpu" {
  description = "CPU allocation"
  type        = number
  default     = 2.0
}

variable "memory" {
  description = "Memory allocation"
  type        = string
  default     = "4Gi"
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
