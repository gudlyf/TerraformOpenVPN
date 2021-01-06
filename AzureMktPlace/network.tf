resource "azurerm_virtual_network" "vnet" {
  name                = "OpenVPNVNet"
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["192.168.50.0/24"]
  location            = var.location
  dns_servers         = ["1.1.1.1", "9.9.9.9"]
}

resource "azurerm_subnet" "VPNSubnet" {
  name                 = "VPNSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["192.168.50.16/28"]
}

resource "azurerm_network_security_group" "sg" {
  name                = "sg-openvpn"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "PermitSSHInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.restrict_ssh == true ? (jsondecode(data.http.geoipdata.body)).geoplugin_request : "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "PermitOpenVPNAdminInbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "943"
    source_address_prefix      = var.restrict_ssh == true ? (jsondecode(data.http.geoipdata.body)).geoplugin_request : "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "PermitOpen443Inbound"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = var.restrict_vpn == true ? (jsondecode(data.http.geoipdata.body)).geoplugin_request : "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "PermitOpen1194Inbound"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "1194"
    source_address_prefix      = var.restrict_vpn == true ? (jsondecode(data.http.geoipdata.body)).geoplugin_request : "*"
    destination_address_prefix = "*"
  }

}

resource "random_string" "dns-name" {
  length  = 4
  upper   = false
  lower   = true
  number  = true
  special = false
}

resource "azurerm_public_ip" "pubip" {
  name                = "${var.hostname}-public"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  allocation_method   = "Static"
  domain_name_label   = "openvpn${random_string.dns-name.result}"
}

resource "azurerm_network_interface" "nic" {
  name                 = var.hostname
  location             = var.location
  resource_group_name  = azurerm_resource_group.rg.name
  enable_ip_forwarding = true

  ip_configuration {
    name                          = var.hostname
    subnet_id                     = azurerm_subnet.VPNSubnet.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.pubip.id
  }
}

resource "azurerm_route_table" "ovpn_route_table" {
  name                          = "ovpnroutetable"
  location                      = var.location
  resource_group_name           = azurerm_resource_group.rg.name
  disable_bgp_route_propagation = false

  route {
    name                   = "ovpnroute1"
    address_prefix         = "172.27.224.0/20"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_network_interface.nic.private_ip_address
  }

  route {
    name                   = "ovpnroute2"
    address_prefix         = "172.27.240.0/20"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_network_interface.nic.private_ip_address
  }

}
