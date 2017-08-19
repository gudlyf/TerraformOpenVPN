resource "google_compute_network" "ovpn" {
  name                    = "ovpn"
  auto_create_subnetworks = "true"
}

resource "google_compute_firewall" "ovpn" {
  name    = "ovpn-firewall"
  network = "${google_compute_network.ovpn.name}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  allow {
    protocol = "udp"
    ports    = ["1194"]
  }

  target_tags = ["ovpn"]
}
