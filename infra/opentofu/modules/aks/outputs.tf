output "aks_id" {
  description = "ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.id
}

output "aks_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "aks_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.fqdn
}

output "aks_kubelet_identity" {
  description = "Kubelet identity of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.kubelet_identity
}

output "aks_identity" {
  description = "System assigned identity of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.identity[0]
}

output "aks_subnet_id" {
  description = "ID of the AKS subnet"
  value       = azurerm_subnet.aks_subnet.id
}

output "kube_config_raw" {
  description = "Raw Kubernetes config"
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}
