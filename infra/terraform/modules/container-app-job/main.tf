resource "azurerm_container_app_job" "job" {
  name                         = "${var.environment}-${var.job_name}"
  container_app_environment_id = var.container_app_environment_id
  resource_group_name          = var.resource_group_name
  location                     = var.location

  # Job configuration
  replica_timeout_in_seconds = var.replica_timeout_in_seconds
  replica_retry_limit        = var.replica_retry_limit

  secret {
    name  = "queue-connection"
    value = var.servicebus_connection_string
  }
  event_trigger_config {
    parallelism              = var.parallelism
    replica_completion_count = var.replica_completion_count

    scale {
      min_executions              = var.min_executions
      max_executions              = var.max_executions
      polling_interval_in_seconds = var.polling_interval_in_seconds

      rules {
        name             = "azure-queue"
        custom_rule_type = "azure-servicebus"
        metadata = {
          namespace    = var.servicebus_namespace_name
          queueName    = var.queue_name
          messageCount = var.message_count_threshold
        }

        authentication {
          secret_name       = "queue-connection"
          trigger_parameter = "connection"
        }
      }
    }
  }

  secret {
    name  = "acr-password"
    value = var.acr_password
  }

  registry {
    server               = var.acr_login_server
    username             = var.acr_username
    password_secret_name = "acr-password"
  }

  template {
    container {
      name   = var.container_name
      image  = "${var.acr_login_server}/${var.image_name}:${var.image_version}"
      cpu    = var.cpu
      memory = var.memory
    }
  }

  tags = var.tags
}
