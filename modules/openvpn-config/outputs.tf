output "user_data" {
  description = "cloud-init (#cloud-config) document that installs and starts OpenVPN. Contains the server private key."
  value       = local.user_data
  sensitive   = true
}

output "user_data_sha256" {
  description = "SHA-256 of user_data, for use as a non-sensitive replacement trigger."
  value       = nonsensitive(sha256(local.user_data))
}

output "client_configs" {
  description = "Map of client name to rendered .ovpn profile content."
  value       = local.client_configs
  sensitive   = true
}

output "client_config_files" {
  description = "Map of client name to the local .ovpn file path (empty when client_config_dir is null)."
  value       = { for c, f in local_sensitive_file.client_config : c => f.filename }
}

output "ca_cert_pem" {
  description = "PEM-encoded CA certificate."
  value       = tls_self_signed_cert.ca.cert_pem
}

output "server_common_name" {
  description = "Common name of the server certificate (clients verify it with verify-x509-name)."
  value       = local.server_common_name
}

output "port" {
  description = "Port OpenVPN listens on."
  value       = var.port
}

output "protocol" {
  description = "Transport protocol OpenVPN uses."
  value       = var.protocol
}
