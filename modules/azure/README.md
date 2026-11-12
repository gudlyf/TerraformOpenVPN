# azure module

Deploys a personal OpenVPN server on Azure using [openvpn-config](../openvpn-config) for PKI, cloud-init and client profiles.

Creates a resource group, VNet and subnet, an NSG attached to the NIC, a Standard static public IP with a DNS label, and an Ubuntu 24.04 `azurerm_linux_virtual_machine`. Azure requires an admin SSH key; when `ssh_public_key` is null a throwaway key is registered and SSH stays closed.

The server keeps its public IP when it is replaced, so client profiles stay valid. SSH is closed unless both `ssh_public_key` and `ssh_allowed_cidrs` are set.

## Usage

```hcl
provider "azurerm" {
  features {}
  subscription_id = "00000000-0000-0000-0000-000000000000"
}

module "vpn" {
  source = "github.com/gudlyf/TerraformOpenVPN//modules/azure?ref=master"

  clients           = ["laptop", "phone"]
  vpn_allowed_cidrs = ["0.0.0.0/0"]
  client_config_dir = "${path.root}/vpn-profiles"
}
```

For a ready-to-run configuration, see [`Azure/`](../../Azure) in the repository root.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.6 |
| azurerm | >= 5.0, < 6.0 |
| local | >= 2.5, < 3.0 |
| random | >= 3.6, < 4.0 |
| tls | >= 4.0, < 5.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >= 5.0, < 6.0 |
| random | >= 3.6, < 4.0 |
| tls | >= 4.0, < 5.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| openvpn\_config | ../openvpn-config | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_linux_virtual_machine.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine) | resource |
| [azurerm_network_interface.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_network_interface_security_group_association.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_security_group_association) | resource |
| [azurerm_network_security_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_public_ip.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_subnet.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_virtual_network.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |
| [random_string.dns](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [tls_private_key.placeholder](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| admin\_username | Admin user on the VM. | `string` | `"ubuntu"` | no |
| cert\_subject | Certificate subject fields (organization, organizational\_unit, country, province, locality). | ```object({ organization = optional(string, "TerraformOpenVPN") organizational_unit = optional(string) country = optional(string) province = optional(string) locality = optional(string) })``` | `{}` | no |
| client\_config\_dir | Directory to write .ovpn files to. Null disables writing files. | `string` | `null` | no |
| client\_config\_prefix | Prefix for generated .ovpn file names. | `string` | `"azure-"` | no |
| clients | Client names to issue .ovpn profiles for. Removing a name revokes that client. | `set(string)` | ```[ "client" ]``` | no |
| dns\_servers | DNS servers pushed to clients. | `list(string)` | ```[ "1.1.1.1", "9.9.9.9" ]``` | no |
| domain\_name\_label | DNS label for the public IP (<label>.<location>.cloudapp.azure.com). Defaults to "<name>-<random>". | `string` | `null` | no |
| full\_tunnel | Route all client traffic through the VPN. | `bool` | `true` | no |
| location | Azure region. | `string` | `"westus2"` | no |
| name | Name prefix for all resources. | `string` | `"openvpn"` | no |
| pushed\_routes | Extra IPv4 CIDR routes pushed to clients. | `list(string)` | `[]` | no |
| resource\_group\_name | Name of the resource group to create. Defaults to "rg-<name>". | `string` | `null` | no |
| source\_image | Marketplace image for the VM. Defaults to Canonical Ubuntu 24.04 LTS (x64, Gen2). | ```object({ publisher = string offer = string sku = string version = string })``` | ```{ "offer": "ubuntu-24_04-lts", "publisher": "Canonical", "sku": "server", "version": "latest" }``` | no |
| ssh\_allowed\_cidrs | IPv4 CIDR blocks allowed to SSH to the VM. Empty (the default) means port 22 is closed. | `list(string)` | `[]` | no |
| ssh\_public\_key | OpenSSH public key for admin\_username. If null, a throwaway key is generated (Azure requires one) and SSH stays closed. | `string` | `null` | no |
| tags | Tags applied to all resources. | `map(string)` | `{}` | no |
| vm\_size | VM size. | `string` | `"Standard_B2s"` | no |
| vnet\_cidr | Address space of the virtual network. Must not overlap vpn\_cidr. | `string` | `"10.10.0.0/24"` | no |
| vpn\_allowed\_cidrs | IPv4 CIDR blocks allowed to reach the VPN port. | `list(string)` | ```[ "0.0.0.0/0" ]``` | no |
| vpn\_cidr | IPv4 network handed out to VPN clients. | `string` | `"10.8.0.0/24"` | no |
| vpn\_port | Port OpenVPN listens on. | `number` | `1194` | no |
| vpn\_protocol | "udp" (recommended) or "tcp". | `string` | `"udp"` | no |

## Outputs

| Name | Description |
|------|-------------|
| ca\_cert\_pem | PEM-encoded CA certificate. |
| client\_config\_files | Map of client name to local .ovpn file path. |
| client\_configs | Map of client name to .ovpn profile content. |
| fqdn | DNS name of the VPN server's public IP. |
| public\_ip | Static public IP address of the VPN server. |
| resource\_group\_name | Resource group containing all resources. |
| ssh\_command | SSH command for the server, or null when SSH is disabled. |
| vm\_id | Azure VM ID. |
<!-- END_TF_DOCS -->
