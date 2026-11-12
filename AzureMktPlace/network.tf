resource "azurerm_virtual_network" "this" {
  name                = "vnet-${var.name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = [var.vnet_cidr]
  tags                = local.tags
}

resource "azurerm_subnet" "this" {
  name                            = "snet-${var.name}"
  resource_group_name             = azurerm_resource_group.this.name
  virtual_network_name            = azurerm_virtual_network.this.name
  address_prefixes                = [var.subnet_cidr]
  default_outbound_access_enabled = false
}

resource "azurerm_network_security_group" "this" {
  name                = "nsg-${var.name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags

  security_rule {
    name                       = "AllowAdminUIInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "943"
    source_address_prefixes    = var.admin_allowed_cidrs
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTPSInbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefixes    = var.vpn_allowed_cidrs
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowOpenVPNInbound"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "1194"
    source_address_prefixes    = var.vpn_allowed_cidrs
    destination_address_prefix = "*"
  }

  dynamic "security_rule" {
    for_each = local.ssh_enabled ? [1] : []

    content {
      name                       = "AllowSSHInbound"
      priority                   = 130
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
  domain_name_label   = "${var.name}-${local.suffix}"
  tags                = local.tags
}

resource "azurerm_network_interface" "this" {
  name                  = "nic-${var.name}"
  location              = azurerm_resource_group.this.location
  resource_group_name   = azurerm_resource_group.this.name
  ip_forwarding_enabled = true # Access Server routes VPN client subnets
  tags                  = local.tags

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

# Lets other resources in the VNet reach VPN clients through Access Server.
resource "azurerm_route_table" "this" {
  name                = "rt-${var.name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags

  dynamic "route" {
    for_each = var.vpn_client_cidrs

    content {
      name                   = "vpn-clients-${route.key}"
      address_prefix         = route.value
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = azurerm_network_interface.this.private_ip_address
    }
  }
}

resource "azurerm_subnet_route_table_association" "this" {
  subnet_id      = azurerm_subnet.this.id
  route_table_id = azurerm_route_table.this.id
}
