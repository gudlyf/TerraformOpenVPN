provider "azurerm" {
}

resource "azurerm_resource_group" "rg" {
  name     = "vpn"
  location = var.location
}

terraform {
  required_version = ">= 0.12"
}
