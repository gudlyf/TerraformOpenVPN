output "public_ip" {
  description = "VPN server address."
  value       = module.openvpn.public_ip
}

output "fqdn" {
  description = "DNS name of the VPN server."
  value       = module.openvpn.fqdn
}

output "client_config_files" {
  description = "Client profiles written to disk. Import these into your OpenVPN client."
  value       = module.openvpn.client_config_files
}

output "client_configs" {
  description = "Client profile contents (terraform output -json client_configs)."
  value       = module.openvpn.client_configs
  sensitive   = true
}

output "ssh_command" {
  description = "SSH command for the server, or null when SSH is disabled."
  value       = module.openvpn.ssh_command
}

output "next_steps" {
  description = "What to do after apply."
  value       = "The server finishes installing OpenVPN 2-5 minutes after apply. Then import the .ovpn file(s) listed in client_config_files into your OpenVPN client."
}
