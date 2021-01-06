resource "azurerm_linux_virtual_machine" "openvpn" {
  name                  = var.hostname
  admin_username        = var.admin_username
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  size                  = "Standard_B2s"
  custom_data           = data.template_cloudinit_config.config.rendered

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.public_key_file)
  }

  plan {
    publisher = "openvpn"
    product   = "openvpnas"
    name      = "access_server_byol"
  }

  source_image_reference {
    publisher = "openvpn"
    offer     = "openvpnas"
    sku       = "access_server_byol"
    version   = "latest"
  }

  #This would be the vanilla image, not using this
  #source_image_reference {
  #  publisher = "Canonical"
  #  offer     = "UbuntuServer"
  #  sku       = "18.04-LTS"
  #  version   = "latest"
  #}

  os_disk {
    name                 = "${var.hostname}_os"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  connection {
    type        = "ssh"
    host        = azurerm_public_ip.pubip.ip_address
    user        = var.admin_username
    private_key = file(var.private_key_file)
  }

}

data "template_file" "cloudconfig" {
  template = file("cloud-init.txt")
  vars = {
    ovpnadmin_password = random_password.ovpnadmin_password.result
    ovpnadmin_username = var.ovpnadmin_username
    domain_name_label  = azurerm_public_ip.pubip.fqdn
  }
}

data "template_file" "openvpnconfig" {
  template = file("openvpncfg.txt")
  vars = {
    domain_name_label  = azurerm_public_ip.pubip.fqdn
    ovpnadmin_username = var.ovpnadmin_username
  }
}

data "template_cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = data.template_file.cloudconfig.rendered
  }

  part {
    content_type = "text/plain"
    content      = data.template_file.openvpnconfig.rendered
  }

}
