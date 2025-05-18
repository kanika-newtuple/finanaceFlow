output "app_gateway_id" {
  description = "The ID of the Application Gateway"
  value       = azurerm_application_gateway.appgw.id
}

output "app_gateway_name" {
  description = "The name of the Application Gateway"
  value       = azurerm_application_gateway.appgw.name
}

output "app_gateway_public_ip" {
  description = "The public IP address of the Application Gateway"
  value       = azurerm_public_ip.appgw_ip.ip_address
}

output "app_gateway_private_ip" {
  description = "The private IP address of the Application Gateway"
  value       = var.private_ip_address
}

output "waf_policy_id" {
  description = "The ID of the WAF policy"
  value       = azurerm_web_application_firewall_policy.waf_policy.id
}

output "private_dns_zone_id" {
  description = "The ID of the private DNS zone"
  value       = var.create_private_dns ? azurerm_private_dns_zone.private_dns[0].id : null
}

output "private_dns_zone_name" {
  description = "The name of the private DNS zone"
  value       = var.create_private_dns ? azurerm_private_dns_zone.private_dns[0].name : null
}


output "app_gateway_subnet_id" {
  description = "The ID of the Application Gateway subnet"
  value       = azurerm_subnet.appgw_subnet.id
}