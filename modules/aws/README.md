# aws module

Deploys a personal OpenVPN server on AWS using [openvpn-config](../openvpn-config) for PKI, cloud-init and client profiles.

Creates a dedicated VPC, public subnet, security group, an ENI with an Elastic IP, and an Ubuntu 24.04 EC2 instance (Graviton `t4g.micro` by default; the matching AMI architecture is picked automatically). IMDSv2 is required and the root volume is encrypted.

The server keeps its public IP when it is replaced, so client profiles stay valid. SSH is closed unless both `ssh_public_key` and `ssh_allowed_cidrs` are set.

## Usage

```hcl
provider "aws" {
  region = "us-east-1"
}

module "vpn" {
  source = "github.com/gudlyf/TerraformOpenVPN//modules/aws?ref=master"

  clients           = ["laptop", "phone"]
  vpn_allowed_cidrs = ["0.0.0.0/0"]
  client_config_dir = "${path.root}/vpn-profiles"
}
```

For a ready-to-run configuration, see [`AWS/`](../../AWS) in the repository root.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.6 |
| aws | >= 6.0, < 7.0 |
| local | >= 2.5, < 3.0 |
| random | >= 3.6, < 4.0 |
| tls | >= 4.0, < 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 6.0, < 7.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| openvpn\_config | ../openvpn-config | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_eip.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_instance.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_internet_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_key_pair.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) | resource |
| [aws_network_interface.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface) | resource |
| [aws_route_table.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_subnet.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_vpc_security_group_egress_rule.all](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.ssh](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.vpn](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_ami.ubuntu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_ec2_instance_type.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ec2_instance_type) | data source |
| [aws_ec2_instance_type_offerings.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ec2_instance_type_offerings) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| ami\_id | Override the AMI. Defaults to the latest Canonical Ubuntu 24.04 LTS image for the instance type's architecture. | `string` | `null` | no |
| availability\_zone | Availability zone to launch in. Defaults to the first zone that offers instance\_type. | `string` | `null` | no |
| cert\_subject | Certificate subject fields (organization, organizational\_unit, country, province, locality). | ```object({ organization = optional(string, "TerraformOpenVPN") organizational_unit = optional(string) country = optional(string) province = optional(string) locality = optional(string) })``` | `{}` | no |
| client\_config\_dir | Directory to write .ovpn files to. Null disables writing files. | `string` | `null` | no |
| client\_config\_prefix | Prefix for generated .ovpn file names. | `string` | `"aws-"` | no |
| clients | Client names to issue .ovpn profiles for. Removing a name revokes that client. | `set(string)` | ```[ "client" ]``` | no |
| dns\_servers | DNS servers pushed to clients. | `list(string)` | ```[ "1.1.1.1", "9.9.9.9" ]``` | no |
| full\_tunnel | Route all client traffic through the VPN. | `bool` | `true` | no |
| instance\_type | EC2 instance type. Graviton (arm64) and x86\_64 types both work; the matching Ubuntu AMI is picked automatically. | `string` | `"t4g.micro"` | no |
| name | Name prefix for all resources. | `string` | `"openvpn"` | no |
| pushed\_routes | Extra IPv4 CIDR routes pushed to clients. | `list(string)` | `[]` | no |
| root\_volume\_size | Root volume size in GiB. | `number` | `8` | no |
| ssh\_allowed\_cidrs | IPv4 CIDR blocks allowed to SSH to the instance. Empty (the default) means port 22 is closed. | `list(string)` | `[]` | no |
| ssh\_public\_key | OpenSSH public key for the "ubuntu" user. SSH is optional; leave null to launch without a key pair. | `string` | `null` | no |
| tags | Tags applied to all resources. | `map(string)` | `{}` | no |
| vpc\_cidr | CIDR block for the dedicated VPC. Must not overlap vpn\_cidr. | `string` | `"10.10.0.0/24"` | no |
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
| instance\_id | EC2 instance ID. |
| public\_ip | Elastic IP address of the VPN server. |
| ssh\_command | SSH command for the server, or null when SSH is disabled. |
<!-- END_TF_DOCS -->
