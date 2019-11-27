output "public_ip" {
  value = "VPN IP Address: ${aws_instance.ovpn.public_ip}"
}

