output "public_ip" {
  description = "Static public IP address of the VPN server."
  value       = azurerm_public_ip.this.ip_address
}

output "fqdn" {
  description = "DNS name of the VPN server's public IP."
  value       = azurerm_public_ip.this.fqdn
}

output "resource_group_name" {
  description = "Resource group containing all resources."
  value       = azurerm_resource_group.this.name
}

output "vm_id" {
  description = "Azure VM ID."
  value       = azurerm_linux_virtual_machine.this.id
}

output "client_config_files" {
  description = "Map of client name to local .ovpn file path."
  value       = module.openvpn_config.client_config_files
}

output "client_configs" {
  description = "Map of client name to .ovpn profile content."
  value       = module.openvpn_config.client_configs
  sensitive   = true
}

output "ca_cert_pem" {
  description = "PEM-encoded CA certificate."
  value       = module.openvpn_config.ca_cert_pem
}

output "ssh_command" {
  description = "SSH command for the server, or null when SSH is disabled."
  value       = local.ssh_enabled ? "ssh ${var.admin_username}@${azurerm_public_ip.this.ip_address}" : null
}
