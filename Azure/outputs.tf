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