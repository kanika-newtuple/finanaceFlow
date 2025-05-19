output "jumpbox_id" {
  description = "The ID of the jumpbox VM"
  value       = azurerm_linux_virtual_machine.jumpbox.id
}

output "jumpbox_public_ip" {
  description = "The public IP address of the jumpbox VM"
  value       = azurerm_public_ip.jumpbox_ip.ip_address
}

output "jumpbox_subnet_id" {
  description = "The ID of the jumpbox subnet"
  value       = azurerm_subnet.jumpbox_subnet.id
}

output "jumpbox_username" {
  description = "The admin username for the jumpbox VM"
  value       = var.jumpbox_admin_username
}
