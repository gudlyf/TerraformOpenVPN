# Plan/apply the Azure module against a mocked azurerm provider.
# Run with: terraform test   (no Azure credentials required)

mock_provider "azurerm" {
  # Resource IDs must look like Azure IDs to pass provider-side validation.
  mock_resource "azurerm_resource_group" {
    defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-openvpn" }
  }

  mock_resource "azurerm_virtual_network" {
    defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-openvpn/providers/Microsoft.Network/virtualNetworks/vnet-openvpn" }
  }

  mock_resource "azurerm_subnet" {
    defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-openvpn/providers/Microsoft.Network/virtualNetworks/vnet-openvpn/subnets/snet-openvpn" }
  }

  mock_resource "azurerm_public_ip" {
    defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-openvpn/providers/Microsoft.Network/publicIPAddresses/pip-openvpn" }
  }

  mock_resource "azurerm_network_interface" {
    defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-openvpn/providers/Microsoft.Network/networkInterfaces/nic-openvpn" }
  }

  mock_resource "azurerm_network_security_group" {
    defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-openvpn/providers/Microsoft.Network/networkSecurityGroups/nsg-openvpn" }
  }

  mock_resource "azurerm_linux_virtual_machine" {
    defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-openvpn/providers/Microsoft.Compute/virtualMachines/vm-openvpn" }
  }

  override_resource {
    target = azurerm_public_ip.this
    values = {
      id         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-openvpn/providers/Microsoft.Network/publicIPAddresses/pip-openvpn"
      ip_address = "203.0.113.30"
    }
  }
}

run "defaults" {
  assert {
    condition     = length(azurerm_network_security_group.this.security_rule) == 1
    error_message = "Only the VPN rule should exist by default (SSH closed)."
  }

  assert {
    condition     = one(azurerm_network_security_group.this.security_rule).protocol == "Udp"
    error_message = "VPN rule must be UDP by default."
  }

  assert {
    condition     = azurerm_public_ip.this.sku == "Standard" && azurerm_public_ip.this.allocation_method == "Static"
    error_message = "Public IP must be a static Standard SKU."
  }

  assert {
    condition     = azurerm_network_interface_security_group_association.this.network_security_group_id == azurerm_network_security_group.this.id
    error_message = "The NSG must be associated with the NIC."
  }

  assert {
    condition     = strcontains(nonsensitive(module.openvpn_config.client_configs["client"]), "remote 203.0.113.30 1194")
    error_message = "Client profile must use the static public IP."
  }
}

run "ssh_enabled" {
  variables {
    ssh_public_key    = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGtxl2X4gk5ywJSqPLUvd+SVQIDGb/kqzONGmNI9PZGo test"
    ssh_allowed_cidrs = ["198.51.100.7/32"]
  }

  assert {
    condition     = length(azurerm_network_security_group.this.security_rule) == 2
    error_message = "SSH rule expected when a key and CIDRs are given."
  }
}
