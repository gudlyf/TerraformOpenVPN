resource "azurerm_virtual_machine" "openvpn" {
  name                  = var.hostname
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size               = "Standard_B2s"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.hostname}_os"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    admin_username = var.admin_username
    computer_name  = var.hostname
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = file(var.public_key_file)
    }
  }

  connection {
    type        = "ssh"
    host        = azurerm_public_ip.pubip.ip_address
    user        = var.admin_username
    private_key = file(var.private_key_file)
  }

  provisioner "file" {
    content     = data.template_file.deployment_shell_script.rendered
    destination = "/tmp/userdata.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/userdata.sh",
      "sudo /tmp/userdata.sh",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for client config ...'",
      "while [ ! -f /etc/openvpn/client.ovpn ]; do sleep 5; done",
      "echo 'DONE!'",
    ]

    connection {
      host        = azurerm_public_ip.pubip.ip_address
      type        = "ssh"
      user        = var.admin_username
      private_key = file(var.private_key_file)
      timeout     = "5m"
    }
  }

  provisioner "local-exec" {
    command = "scp -o StrictHostKeyChecking=no -i ${var.private_key_file} ${var.admin_username}@${azurerm_public_ip.pubip.ip_address}:/etc/openvpn/client.ovpn ${var.client_config_path}/${var.client_config_name}.ovpn"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Scheduling instance reboot in one minute ...'",
      "sudo shutdown -r +1",
    ]

    connection {
      host        = azurerm_public_ip.pubip.ip_address
      type        = "ssh"
      user        = var.admin_username
      private_key = file(var.private_key_file)
      timeout     = "5m"
    }
  }

  #provisioner "local-exec" {
  #  command = "rm -f ${var.client_config_path}/${var.client_config_name}.ovpn"
  #  when    = destroy
  #}
}

data "template_file" "deployment_shell_script" {
  template = file("userdata.sh")

  vars = {
    cert_details       = file(var.cert_details)
    client_config_name = var.client_config_name
  }
}

