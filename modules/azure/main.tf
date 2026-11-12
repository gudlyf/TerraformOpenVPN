locals {
  tags = merge({ ManagedBy = "terraform", Project = "TerraformOpenVPN" }, var.tags)

  resource_group_name = coalesce(var.resource_group_name, "rg-${var.name}")
  domain_name_label   = coalesce(var.domain_name_label, "${var.name}-${random_string.dns.result}")
  ssh_enabled         = var.ssh_public_key != null && length(var.ssh_allowed_cidrs) > 0
  ssh_public_key      = coalesce(var.ssh_public_key, tls_private_key.placeholder.public_key_openssh)
  vpn_protocol        = title(var.vpn_protocol) # Azure expects "Udp" / "Tcp"
}

resource "random_string" "dns" {
  length  = 6
  upper   = false
  special = false
}

# Azure Linux VMs require an SSH key or password. When no key is supplied we
# register a generated one that nobody keeps, and SSH stays closed.
resource "tls_private_key" "placeholder" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

################################################################################
# OpenVPN configuration (PKI, cloud-init, client profiles)
################################################################################

module "openvpn_config" {
  source = "../openvpn-config"

  name                 = var.name
  server_address       = azurerm_public_ip.this.ip_address
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

resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.tags
}

resource "azurerm_virtual_network" "this" {
  name                = "vnet-${var.name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = [var.vnet_cidr]
  tags                = local.tags
}

resource "azurerm_subnet" "this" {
  name                 = "snet-${var.name}"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.vnet_cidr]

  # Outbound traffic leaves through the VM's own public IP.
  default_outbound_access_enabled = false
}

resource "azurerm_network_security_group" "this" {
  name                = "nsg-${var.name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags

  security_rule {
    name                       = "AllowOpenVPNInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = local.vpn_protocol
    source_port_range          = "*"
    destination_port_range     = tostring(var.vpn_port)
    source_address_prefixes    = var.vpn_allowed_cidrs
    destination_address_prefix = "*"
  }

  dynamic "security_rule" {
    for_each = local.ssh_enabled ? [1] : []

    content {
      name                       = "AllowSSHInbound"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefixes    = var.ssh_allowed_cidrs
      destination_address_prefix = "*"
    }
  }
}

resource "azurerm_public_ip" "this" {
  name                = "pip-${var.name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = local.domain_name_label
  tags                = local.tags
}

resource "azurerm_network_interface" "this" {
  name                = "nic-${var.name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.this.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.this.id
  }
}

# Standard SKU public IPs deny all inbound traffic unless an NSG allows it.
resource "azurerm_network_interface_security_group_association" "this" {
  network_interface_id      = azurerm_network_interface.this.id
  network_security_group_id = azurerm_network_security_group.this.id
}

################################################################################
# Virtual machine
################################################################################

resource "azurerm_linux_virtual_machine" "this" {
  name                  = "vm-${var.name}"
  computer_name         = var.name
  location              = azurerm_resource_group.this.location
  resource_group_name   = azurerm_resource_group.this.name
  size                  = var.vm_size
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.this.id]

  # Changing custom_data replaces the VM; the public IP is kept.
  custom_data = base64encode(module.openvpn_config.user_data)

  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = local.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = var.source_image.publisher
    offer     = var.source_image.offer
    sku       = var.source_image.sku
    version   = var.source_image.version
  }

  # Managed boot diagnostics enable the serial console for troubleshooting.
  boot_diagnostics {}

  tags = local.tags

  depends_on = [azurerm_network_interface_security_group_association.this]
}
