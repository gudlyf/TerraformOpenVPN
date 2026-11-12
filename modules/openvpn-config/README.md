# openvpn-config

Cloud-agnostic core of TerraformOpenVPN. Given the address clients will connect to, it:

- generates a CA, a server certificate and one client certificate per entry in `clients` (ECDSA P-256), plus a `tls-crypt` key;
- renders a `#cloud-config` document (`user_data`) that installs OpenVPN 2.6 from the Ubuntu archive, writes the server configuration and keys, enables IP forwarding, installs a small NAT service and starts `openvpn-server@server`;
- renders one inline `.ovpn` profile per client and, if `client_config_dir` is set, writes them to disk with mode `0600`.

It creates no cloud resources, so it works with any Ubuntu 24.04 machine that runs cloud-init. The [aws](../aws), [azure](../azure) and [gcp](../gcp) modules wrap it.

```hcl
module "openvpn_config" {
  source = "github.com/gudlyf/TerraformOpenVPN//modules/openvpn-config?ref=master"

  server_address    = "203.0.113.10"
  clients           = ["laptop", "phone"]
  client_config_dir = "${path.root}/profiles"
}

# Pass module.openvpn_config.user_data to your VM as cloud-init user data.
```

The server allows only clients listed in `clients` (`ccd-exclusive`), so removing a client revokes it once the server is rebuilt with the new user data.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.6 |
| local | >= 2.5, < 3.0 |
| random | >= 3.6, < 4.0 |
| tls | >= 4.0, < 5.0 |

## Providers

| Name | Version |
|------|---------|
| local | >= 2.5, < 3.0 |
| random | >= 3.6, < 4.0 |
| tls | >= 4.0, < 5.0 |

## Resources

| Name | Type |
|------|------|
| [local_sensitive_file.client_config](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/sensitive_file) | resource |
| [random_bytes.tls_crypt](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/bytes) | resource |
| [tls_cert_request.client](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/cert_request) | resource |
| [tls_cert_request.server](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/cert_request) | resource |
| [tls_locally_signed_cert.client](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/locally_signed_cert) | resource |
| [tls_locally_signed_cert.server](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/locally_signed_cert) | resource |
| [tls_private_key.ca](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_private_key.client](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_private_key.server](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_self_signed_cert.ca](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/self_signed_cert) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| server\_address | Public IP address or DNS name that clients connect to. Written into each client profile. | `string` | n/a | yes |
| ca\_validity\_hours | Validity period of the CA certificate, in hours. Default is 10 years. | `number` | `87600` | no |
| cert\_subject | Subject fields for the generated certificates (replaces the old cert\_details file). | ```object({ organization = optional(string, "TerraformOpenVPN") organizational_unit = optional(string) country = optional(string) province = optional(string) locality = optional(string) })``` | `{}` | no |
| cert\_validity\_hours | Validity period of server and client certificates, in hours. Default is 5 years. | `number` | `43800` | no |
| client\_config\_dir | Directory to write <prefix><client>.ovpn files to. Set to null to skip writing files (profiles remain available via the client\_configs output). | `string` | `null` | no |
| client\_config\_prefix | Prefix for generated .ovpn file names, e.g. "aws-" gives aws-client.ovpn. | `string` | `""` | no |
| clients | Client names to issue certificates and .ovpn profiles for. Removing a name revokes that client's access. | `set(string)` | ```[ "client" ]``` | no |
| dns\_servers | DNS servers pushed to clients. | `list(string)` | ```[ "1.1.1.1", "9.9.9.9" ]``` | no |
| enable\_fail2ban | Install fail2ban with an sshd jail. Useful only when SSH is reachable. | `bool` | `false` | no |
| full\_tunnel | Route all client traffic through the VPN. Set to false for split tunnelling with pushed\_routes. | `bool` | `true` | no |
| name | Name used as a prefix for certificate common names. | `string` | `"openvpn"` | no |
| port | Port OpenVPN listens on. | `number` | `1194` | no |
| protocol | Transport protocol: "udp" (recommended) or "tcp". | `string` | `"udp"` | no |
| pushed\_routes | Extra IPv4 CIDR routes pushed to clients (mainly useful when full\_tunnel is false). | `list(string)` | `[]` | no |
| reboot\_if\_required | Reboot at the end of first boot if package upgrades require it. | `bool` | `true` | no |
| upgrade\_packages | Run a full package upgrade on first boot. | `bool` | `true` | no |
| vpn\_cidr | IPv4 network handed out to VPN clients. Must not overlap the cloud network or your local networks. | `string` | `"10.8.0.0/24"` | no |

## Outputs

| Name | Description |
|------|-------------|
| ca\_cert\_pem | PEM-encoded CA certificate. |
| client\_config\_files | Map of client name to the local .ovpn file path (empty when client\_config\_dir is null). |
| client\_configs | Map of client name to rendered .ovpn profile content. |
| port | Port OpenVPN listens on. |
| protocol | Transport protocol OpenVPN uses. |
| server\_common\_name | Common name of the server certificate (clients verify it with verify-x509-name). |
| user\_data | cloud-init (#cloud-config) document that installs and starts OpenVPN. Contains the server private key. |
| user\_data\_sha256 | SHA-256 of user\_data, for use as a non-sensitive replacement trigger. |
<!-- END_TF_DOCS -->
