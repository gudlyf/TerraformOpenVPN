output "public_ip" {
  value = "VPN IP Address: ${google_compute_instance.ovpn.network_interface.0.access_config.0.assigned_nat_ip}"
}
