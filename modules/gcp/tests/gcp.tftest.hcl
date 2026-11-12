# Plan/apply the GCP module against a mocked google provider.
# Run with: terraform test   (no GCP credentials required)

mock_provider "google" {
  override_data {
    target = data.google_compute_zones.available
    values = { names = ["northamerica-northeast1-c", "northamerica-northeast1-a", "northamerica-northeast1-b"] }
  }

  override_resource {
    target = google_compute_address.this
    values = { address = "203.0.113.40" }
  }
}

run "defaults" {
  assert {
    condition     = google_compute_instance.this.zone == "northamerica-northeast1-a"
    error_message = "Should default to the first available zone."
  }

  assert {
    condition     = length(google_compute_firewall.ssh) == 0
    error_message = "SSH must be closed by default."
  }

  assert {
    condition     = one(google_compute_firewall.vpn.allow).protocol == "udp"
    error_message = "VPN firewall rule must be UDP by default."
  }

  assert {
    condition     = !contains(keys(google_compute_instance.this.metadata), "ssh-keys")
    error_message = "No SSH key metadata by default."
  }

  assert {
    condition     = startswith(nonsensitive(google_compute_instance.this.metadata["user-data"]), "#cloud-config")
    error_message = "cloud-init user-data must be set."
  }

  assert {
    condition     = strcontains(nonsensitive(module.openvpn_config.client_configs["client"]), "remote 203.0.113.40 1194")
    error_message = "Client profile must use the static address."
  }
}

run "ssh_enabled" {
  variables {
    ssh_public_key    = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGtxl2X4gk5ywJSqPLUvd+SVQIDGb/kqzONGmNI9PZGo test"
    ssh_allowed_cidrs = ["198.51.100.7/32"]
  }

  assert {
    condition     = length(google_compute_firewall.ssh) == 1
    error_message = "SSH firewall rule expected when a key and CIDRs are given."
  }

  assert {
    condition     = startswith(google_compute_instance.this.metadata["ssh-keys"], "ubuntu:ssh-ed25519 ")
    error_message = "ssh-keys metadata must be set for ssh_user."
  }
}
