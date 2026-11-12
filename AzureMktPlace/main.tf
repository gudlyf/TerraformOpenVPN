provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
}

locals {
  tags        = merge({ ManagedBy = "terraform", Project = "TerraformOpenVPN" }, var.tags)
  suffix      = random_string.suffix.result
  ssh_enabled = var.ssh_public_key_file != null && length(var.ssh_allowed_cidrs) > 0
  ssh_public_key = (
    var.ssh_public_key_file == null
    ? tls_private_key.placeholder.public_key_openssh
    : file(pathexpand(var.ssh_public_key_file))
  )
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "random_password" "ovpnadmin" {
  length           = 20
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
  override_special = "!@#%^*-_=+"
}

# Azure Linux VMs require an SSH key or password. When no key is supplied we
# register a generated one that nobody keeps, and SSH stays closed.
resource "tls_private_key" "placeholder" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${var.name}-${local.suffix}"
  location = var.location
  tags     = local.tags
}

resource "azurerm_marketplace_agreement" "openvpnas" {
  count = var.accept_marketplace_terms ? 1 : 0

  publisher = var.marketplace_image.publisher
  offer     = var.marketplace_image.offer
  plan      = var.marketplace_image.sku
}
