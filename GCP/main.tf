# Credentials come from Application Default Credentials:
#   gcloud auth application-default login
provider "google" {
  project = var.project
  region  = var.region
}

module "openvpn" {
  source = "../modules/gcp"

  name              = var.name
  clients           = var.clients
  vpn_port          = var.vpn_port
  vpn_protocol      = var.vpn_protocol
  vpn_cidr          = var.vpn_cidr
  dns_servers       = var.dns_servers
  full_tunnel       = var.full_tunnel
  vpn_allowed_cidrs = var.vpn_allowed_cidrs
  ssh_public_key    = var.ssh_public_key_file == null ? null : file(pathexpand(var.ssh_public_key_file))
  ssh_allowed_cidrs = var.ssh_allowed_cidrs
  cert_subject      = var.cert_subject
  client_config_dir = var.client_config_dir

  region       = var.region
  zone         = var.zone
  machine_type = var.machine_type

  client_config_prefix = "gcp-"
}
