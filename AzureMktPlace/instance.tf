data "cloudinit_config" "this" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content = "#cloud-config\n${yamlencode({
      package_update  = true
      package_upgrade = true
      runcmd = [
        ["ovpn-init", "--batch", "--host", azurerm_public_ip.this.fqdn],
      ]
      users = [
        "default",
        { name = var.ovpnadmin_username, lock_passwd = false },
      ]
      chpasswd = {
        expire = false
        users = [
          { name = var.ovpnadmin_username, password = random_password.ovpnadmin.result, type = "text" },
        ]
      }
      power_state = {
        mode      = "reboot"
        delay     = "now"
        message   = "Rebooting to finish applying package upgrades"
        condition = ["test", "-f", "/var/run/reboot-required"]
      }
    })}"
  }

  # Access Server initial settings, read by the image on first boot.
  part {
    content_type = "text/plain"
    content = templatefile("${path.module}/openvpncfg.txt.tftpl", {
      domain_name_label  = azurerm_public_ip.this.fqdn
      ovpnadmin_username = var.ovpnadmin_username
    })
  }
}

resource "azurerm_linux_virtual_machine" "this" {
  name                  = "vm-${var.name}"
  computer_name         = var.name
  location              = azurerm_resource_group.this.location
  resource_group_name   = azurerm_resource_group.this.name
  size                  = var.vm_size
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.this.id]
  custom_data           = data.cloudinit_config.this.rendered

  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = local.ssh_public_key
  }

  plan {
    publisher = var.marketplace_image.publisher
    product   = var.marketplace_image.offer
    name      = var.marketplace_image.sku
  }

  source_image_reference {
    publisher = var.marketplace_image.publisher
    offer     = var.marketplace_image.offer
    sku       = var.marketplace_image.sku
    version   = var.marketplace_image.version
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  boot_diagnostics {}

  tags = local.tags

  depends_on = [
    azurerm_marketplace_agreement.openvpnas,
    azurerm_network_interface_security_group_association.this,
  ]
}
