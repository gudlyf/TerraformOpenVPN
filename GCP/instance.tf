resource "google_compute_instance" "ovpn" {
  name         = "ovpn"
  machine_type = "n1-standard-1"
  zone         = var.zone

  tags = ["ovpn"]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
    }
  }

  can_ip_forward = true

  network_interface {
    network = google_compute_network.ovpn.name

    access_config {
      // Ephemeral IP
    }
  }

  service_account {
    scopes = ["https://www.googleapis.com/auth/compute.readonly"]
  }

  metadata = {
    startup-script = data.template_file.deployment_shell_script.rendered
    sshKeys        = "ubuntu:${file(var.public_key_file)}"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for client config ...'",
      "while [ ! -f /etc/openvpn/client.ovpn ]; do sleep 5; done",
      "echo 'DONE!'",
    ]

    connection {
      host        = google_compute_instance.ovpn.network_interface[0].access_config[0].nat_ip
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_file)
      timeout     = "5m"
    }
  }

  provisioner "local-exec" {
    command = "scp -o StrictHostKeyChecking=no -i ${var.private_key_file} ubuntu@${google_compute_instance.ovpn.network_interface[0].access_config[0].nat_ip}:/etc/openvpn/client.ovpn ${var.client_config_path}/${var.client_config_name}.ovpn"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Scheduling instance reboot in one minute ...'",
      "sudo shutdown -r +1",
    ]

    connection {
      host        = google_compute_instance.ovpn.network_interface[0].access_config[0].nat_ip
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_file)
      timeout     = "5m"
    }
  }

  provisioner "local-exec" {
    command = "rm -f ${var.client_config_path}/${var.client_config_name}.ovpn"
    when    = destroy
  }
}

data "google_compute_image" "ubuntu" {
  family  = "ubuntu-1604-lts"
  project = "ubuntu-os-cloud"
}

data "template_file" "deployment_shell_script" {
  template = file("userdata.sh")

  vars = {
    cert_details       = file(var.cert_details)
    client_config_name = var.client_config_name
  }
}

