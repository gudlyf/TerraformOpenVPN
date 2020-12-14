output "public_ip" {
  value = "The VPN Public IP Address: ${azurerm_public_ip.pubip.ip_address}"
}

output "public_dns" {
  value = "The VPN Public DNS: ${azurerm_public_ip.pubip.fqdn}"
}

output "restrict_ssh" {
  value = var.restrict_ssh == true ? "SSH access has been restricted to requests from IP ${(jsondecode(data.http.geoipdata.body)).geoplugin_request}" : "SSH Access has NOT been restricted and is open to the entire internet"
}

output "restrict_vpn" {
  value = var.restrict_vpn == true ? "VPN access has been restricted to requests from IP ${(jsondecode(data.http.geoipdata.body)).geoplugin_request}" : "VPN Access has NOT been restricted and is open to the entire internet"
}

output "admin_url" {
  value = "The VPN admin console url is: https://${azurerm_public_ip.pubip.fqdn}:943/admin"
}

output "admin_info" {
  value = "The VPN admin username is:${var.ovpnadmin_username} with password of:${random_password.ovpnadmin_password.result}"
}

output "be_patient" {
  value = "Cloud-init will bootstrap and restart the machine if needed so the vm will take 1-10 mins to be ready"
}
