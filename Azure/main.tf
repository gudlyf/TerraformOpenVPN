provider "azurerm" {
  features{}
}

resource "azurerm_resource_group" "rg" {
  name     = "vpn"
  location = var.location
}

terraform {
  required_version = ">= 0.12"
}

/* # This somehow started erroring on me after it worked before, not sure why so not using this, but leaving it in as an alternate option
# Grab current source internet ip to use for nsg
data "http" "myextip" {
url = "http://v4.ident.me"
}
*/

# Grab current source internet ip to use for nsg
data "http" "geoipdata" {
  url = "http://www.geoplugin.net/json.gp"

  # Optional request headers
  request_headers = {
    Accept = "application/json"
  }
}
