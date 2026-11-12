locals {
  labels      = merge({ managed-by = "terraform", project = "terraformopenvpn" }, var.labels)
  ssh_enabled = var.ssh_public_key != null && length(var.ssh_allowed_cidrs) > 0
  zone        = coalesce(var.zone, try(sort(data.google_compute_zones.available.names)[0], null))
  network_tag = var.name
}

data "google_compute_zones" "available" {
  region = var.region
  status = "UP"
}

################################################################################
# OpenVPN configuration (PKI, cloud-init, client profiles)
################################################################################

module "openvpn_config" {
  source = "../openvpn-config"

  name                 = var.name
  server_address       = google_compute_address.this.address
  clients              = var.clients
  port                 = var.vpn_port
  protocol             = var.vpn_protocol
  vpn_cidr             = var.vpn_cidr
  dns_servers          = var.dns_servers
  full_tunnel          = var.full_tunnel
  pushed_routes        = var.pushed_routes
  cert_subject         = var.cert_subject
  client_config_dir    = var.client_config_dir
  client_config_prefix = var.client_config_prefix
  enable_fail2ban      = local.ssh_enabled
}

################################################################################
# Network
################################################################################

resource "google_compute_network" "this" {
  name                    = var.name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "this" {
  name          = var.name
  region        = var.region
  network       = google_compute_network.this.id
  ip_cidr_range = var.subnet_cidr
}

resource "google_compute_firewall" "vpn" {
  name          = "${var.name}-vpn"
  network       = google_compute_network.this.id
  direction     = "INGRESS"
  source_ranges = var.vpn_allowed_cidrs
  target_tags   = [local.network_tag]

  allow {
    protocol = var.vpn_protocol
    ports    = [tostring(var.vpn_port)]
  }
}

resource "google_compute_firewall" "ssh" {
  count = local.ssh_enabled ? 1 : 0

  name          = "${var.name}-ssh"
  network       = google_compute_network.this.id
  direction     = "INGRESS"
  source_ranges = var.ssh_allowed_cidrs
  target_tags   = [local.network_tag]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_address" "this" {
  name         = var.name
  region       = var.region
  address_type = "EXTERNAL"
  network_tier = "PREMIUM"
  labels       = local.labels
}

################################################################################
# Instance
################################################################################

# cloud-init only runs once per instance, so a configuration change must
# replace the instance (the static address is kept).
resource "terraform_data" "user_data" {
  input = module.openvpn_config.user_data_sha256
}

resource "google_compute_instance" "this" {
  name         = var.name
  machine_type = var.machine_type
  zone         = local.zone
  tags         = [local.network_tag]
  labels       = local.labels

  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image  = var.image
      size   = var.boot_disk_size
      type   = "pd-balanced"
      labels = local.labels
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.this.id

    access_config {
      nat_ip       = google_compute_address.this.address
      network_tier = "PREMIUM"
    }
  }

  # Ubuntu images on GCE run cloud-init from the "user-data" metadata key.
  metadata = merge(
    { user-data = module.openvpn_config.user_data },
    var.ssh_public_key == null ? {} : { ssh-keys = "${var.ssh_user}:${trimspace(var.ssh_public_key)}" },
  )

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  lifecycle {
    replace_triggered_by = [terraform_data.user_data]

    precondition {
      condition     = local.zone != null
      error_message = "No zones are available in region ${var.region}."
    }
  }
}
