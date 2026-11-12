# gcp module

Deploys a personal OpenVPN server on Google Cloud using [openvpn-config](../openvpn-config) for PKI, cloud-init and client profiles.

Creates a custom VPC and subnetwork, firewall rules, a static external address, and an Ubuntu 24.04 Shielded VM (`e2-micro` by default). The instance is replaced whenever the cloud-init document changes, because cloud-init only runs on first boot.

The server keeps its public IP when it is replaced, so client profiles stay valid. SSH is closed unless both `ssh_public_key` and `ssh_allowed_cidrs` are set.

## Usage

```hcl
provider "google" {
  project = "my-project"
  region  = "us-central1"
}

module "vpn" {
  source = "github.com/gudlyf/TerraformOpenVPN//modules/gcp?ref=master"

  clients           = ["laptop", "phone"]
  vpn_allowed_cidrs = ["0.0.0.0/0"]
  client_config_dir = "${path.root}/vpn-profiles"
}
```

For a ready-to-run configuration, see [`GCP/`](../../GCP) in the repository root.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.6 |
| google | >= 8.0, < 9.0 |
| local | >= 2.5, < 3.0 |
| random | >= 3.6, < 4.0 |
| tls | >= 4.0, < 5.0 |

## Providers

| Name | Version |
|------|---------|
| google | >= 8.0, < 9.0 |
| terraform | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| openvpn\_config | ../openvpn-config | n/a |

## Resources

| Name | Type |
|------|------|
| [google_compute_address.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_address) | resource |
| [google_compute_firewall.ssh](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.vpn](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_instance.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance) | resource |
| [google_compute_network.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network) | resource |
| [google_compute_subnetwork.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | resource |
| [terraform_data.user_data](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [google_compute_zones.available](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_zones) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| boot\_disk\_size | Boot disk size in GB. | `number` | `10` | no |
| cert\_subject | Certificate subject fields (organization, organizational\_unit, country, province, locality). | ```object({ organization = optional(string, "TerraformOpenVPN") organizational_unit = optional(string) country = optional(string) province = optional(string) locality = optional(string) })``` | `{}` | no |
| client\_config\_dir | Directory to write .ovpn files to. Null disables writing files. | `string` | `null` | no |
| client\_config\_prefix | Prefix for generated .ovpn file names. | `string` | `"gcp-"` | no |
| clients | Client names to issue .ovpn profiles for. Removing a name revokes that client. | `set(string)` | ```[ "client" ]``` | no |
| dns\_servers | DNS servers pushed to clients. | `list(string)` | ```[ "1.1.1.1", "9.9.9.9" ]``` | no |
| full\_tunnel | Route all client traffic through the VPN. | `bool` | `true` | no |
| image | Boot image. Use the arm64 family (ubuntu-os-cloud/ubuntu-2404-lts-arm64) with Arm machine types such as t2a or c4a. | `string` | `"ubuntu-os-cloud/ubuntu-2404-lts-amd64"` | no |
| labels | Labels applied to resources that support them. | `map(string)` | `{}` | no |
| machine\_type | Compute Engine machine type. | `string` | `"e2-micro"` | no |
| name | Name prefix for all resources. | `string` | `"openvpn"` | no |
| pushed\_routes | Extra IPv4 CIDR routes pushed to clients. | `list(string)` | `[]` | no |
| region | GCP region. | `string` | `"northamerica-northeast1"` | no |
| ssh\_allowed\_cidrs | IPv4 CIDR blocks allowed to SSH to the instance. Empty (the default) means port 22 is closed. | `list(string)` | `[]` | no |
| ssh\_public\_key | OpenSSH public key for ssh\_user. SSH is optional; leave null to skip. | `string` | `null` | no |
| ssh\_user | Username the SSH key is installed for. | `string` | `"ubuntu"` | no |
| subnet\_cidr | CIDR block for the dedicated subnetwork. Must not overlap vpn\_cidr. | `string` | `"10.10.0.0/24"` | no |
| vpn\_allowed\_cidrs | IPv4 CIDR blocks allowed to reach the VPN port. | `list(string)` | ```[ "0.0.0.0/0" ]``` | no |
| vpn\_cidr | IPv4 network handed out to VPN clients. | `string` | `"10.8.0.0/24"` | no |
| vpn\_port | Port OpenVPN listens on. | `number` | `1194` | no |
| vpn\_protocol | "udp" (recommended) or "tcp". | `string` | `"udp"` | no |
| zone | GCP zone. Defaults to the first available zone in region. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| ca\_cert\_pem | PEM-encoded CA certificate. |
| client\_config\_files | Map of client name to local .ovpn file path. |
| client\_configs | Map of client name to .ovpn profile content. |
| instance\_id | Compute Engine instance ID. |
| public\_ip | Static external IP address of the VPN server. |
| ssh\_command | SSH command for the server, or null when SSH is disabled. |
| zone | Zone the instance runs in. |
<!-- END_TF_DOCS -->
