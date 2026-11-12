output "public_ip" {
  description = "Elastic IP address of the VPN server."
  value       = aws_eip.this.public_ip
}

output "instance_id" {
  description = "EC2 instance ID."
  value       = aws_instance.this.id
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
  value       = local.ssh_enabled ? "ssh ubuntu@${aws_eip.this.public_ip}" : null
}
