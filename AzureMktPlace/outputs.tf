output "public_ip" {
  description = "Public IP address of Access Server."
  value       = azurerm_public_ip.this.ip_address
}

output "fqdn" {
  description = "DNS name of Access Server."
  value       = azurerm_public_ip.this.fqdn
}

output "admin_url" {
  description = "Access Server admin UI."
  value       = "https://${azurerm_public_ip.this.fqdn}:943/admin"
}

output "client_url" {
  description = "Access Server client web UI (download profiles and apps here)."
  value       = "https://${azurerm_public_ip.this.fqdn}/"
}

output "admin_username" {
  description = "Admin UI username."
  value       = var.ovpnadmin_username
}

output "admin_password" {
  description = "Admin UI password. Read it with: terraform output -raw admin_password"
  value       = random_password.ovpnadmin.result
  sensitive   = true
}

output "ssh_command" {
  description = "SSH command for the VM, or null when SSH is disabled."
  value       = local.ssh_enabled ? "ssh ${var.admin_username}@${azurerm_public_ip.this.ip_address}" : null
}

output "next_steps" {
  description = "What to do after apply."
  value       = "cloud-init configures Access Server and may reboot the VM; allow 5-10 minutes before opening admin_url. Get the password with: terraform output -raw admin_password"
}
