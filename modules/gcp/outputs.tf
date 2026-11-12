output "public_ip" {
  description = "Static external IP address of the VPN server."
  value       = google_compute_address.this.address
}

output "instance_id" {
  description = "Compute Engine instance ID."
  value       = google_compute_instance.this.instance_id
}

output "zone" {
  description = "Zone the instance runs in."
  value       = google_compute_instance.this.zone
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
  value       = local.ssh_enabled ? "ssh ${var.ssh_user}@${google_compute_address.this.address}" : null
}
