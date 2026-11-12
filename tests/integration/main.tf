# Integration test fixture: renders the shared OpenVPN configuration for a
# server running in a local Docker container. See run.sh.

terraform {
  required_version = ">= 1.6"
}

variable "server_address" {
  type    = string
  default = "172.30.99.10"
}

module "openvpn" {
  source = "../../modules/openvpn-config"

  name              = "it"
  server_address    = var.server_address
  clients           = ["alice", "bob"]
  vpn_cidr          = "10.8.0.0/24"
  client_config_dir = "${path.module}/.out"
  # Containers have no systemd, apt upgrades or reboots; keep first boot lean.
  upgrade_packages   = false
  reboot_if_required = false
}

output "user_data" {
  value     = module.openvpn.user_data
  sensitive = true
}
