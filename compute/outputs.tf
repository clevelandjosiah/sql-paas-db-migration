output "resource_group_name" {
  value = azurerm_resource_group.compute.name
}

output "web_public_ip" {
  value = azurerm_public_ip.web.ip_address
}

output "web_identity_principal_id" {
  description = "Phase 5 verify: the Object (principal) ID"
  value       = var.enable_web_identity ? azurerm_linux_virtual_machine.web.identity[0].principal_id : "identity not enabled yet"
}
