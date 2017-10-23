resource "google_compute_instance" "ovpn" {
  name         = "ovpn"
  machine_type = "n1-standard-1"
  zone         = "${var.zone}"

  tags = ["ovpn"]

  boot_disk {
    initialize_params {
      image = "ubuntu-1404-trusty-v20170811"
    }
  }

  can_ip_forward = true

  network_interface {
    network = "${google_compute_network.ovpn.name}"
    access_config {
      // Ephemeral IP
    }
  }

  metadata {
    startup-script = "${data.template_file.deployment_shell_script.rendered}"
  }

}

data "template_file" "deployment_shell_script" {
  template = "${file("userdata.sh")}"

  vars {
    cert_details = "${file("cert_details")}"
    client_config_name = "${var.client_config_name}"
  }
}
