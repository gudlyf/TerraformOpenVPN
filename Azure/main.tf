provider "azurerm" {}

resource "azurerm_resource_group" "rg" {
  name     = "vpn"
  location = "${var.location}"
}
