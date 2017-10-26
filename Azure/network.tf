resource "azurerm_virtual_network" "vnet" {
  name = "OpenVPNVNet"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  address_space = ["192.168.50.0/24"]
  location = "${var.location}"
  dns_servers = ["8.8.8.8", "8.8.4.4"]
}

resource "azurerm_subnet" "GatewaySubnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  address_prefix       = "192.168.50.0/28"
}

resource "azurerm_subnet" "VPNSubnet" {
  name                 = "VPNSubnet"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  address_prefix       = "192.168.50.16/28"
}


resource "azurerm_network_security_group" "sg" {
  name                = "sg-openvpn"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  security_rule {
    name                       = "PermitSSHInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "PermitOpenVPNInbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "1194"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}

resource "azurerm_public_ip" "pubip" {
  name = "${var.hostname}-public"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${var.location}"
  public_ip_address_allocation = "static"
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.hostname}"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  network_security_group_id = "${azurerm_network_security_group.sg.id}"

  ip_configuration {
    name                          = "${var.hostname}"
    subnet_id                     = "${azurerm_subnet.VPNSubnet.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id = "${azurerm_public_ip.pubip.id}"
  }
}

