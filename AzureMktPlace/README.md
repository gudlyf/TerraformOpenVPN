# AzureMktPlace: OpenVPN Access Server on Azure

This configuration deploys the commercial **OpenVPN Access Server** image from the Azure Marketplace instead of plain Ubuntu and community OpenVPN. You get Access Server's web admin UI, user management and client web portal. It follows OpenVPN's [Azure BYOL quick start guide](https://openvpn.net/vpn-server-resources/microsoft-azure-byol-appliance-quick-start-guide/).

Use this if you want a managed admin UI. If you just want a personal VPN with `.ovpn` files, the [`Azure/`](../Azure) configuration is simpler and needs no license.

## Before you start

- Access Server is **BYOL**: without a license it allows two concurrent connections.
- Accept the marketplace terms once per subscription, either with the CLI:

  ```sh
  az vm image terms accept --publisher openvpn --offer openvpnas --plan openvpnas-gen2
  ```

  or by setting `accept_marketplace_terms = true` (only if they haven't already been accepted, or Terraform will fail creating the agreement).
- The image defaults to `openvpn:openvpnas:openvpnas-gen2` (the original `access_server_byol` SKU no longer has any versions). Marketplace SKUs change from time to time; if `apply` can't find the image, list the current ones with `az vm image list-skus --location westus2 --publisher openvpn --offer openvpnas -o table` and set `marketplace_image`. There's also an `openvpnas-arm64` SKU for Arm VM sizes.

## Usage

```sh
cd AzureMktPlace
cp terraform.tfvars.example terraform.tfvars   # set admin_allowed_cidrs at minimum
terraform init
terraform apply
terraform output -raw admin_password
```

cloud-init runs `ovpn-init --batch` with the public DNS name, sets the admin password and may reboot, so give it 5-10 minutes before opening `admin_url`. Users then download profiles and apps from `client_url`.

## What it creates

- Resource group, VNet and subnet
- Standard static public IP with a `<name>-<random>.<region>.cloudapp.azure.com` DNS name
- NSG attached to the NIC: TCP 943 (admin UI) from `admin_allowed_cidrs`; TCP 443 and UDP 1194 from `vpn_allowed_cidrs`; SSH only if you set a key and `ssh_allowed_cidrs`
- A route table on the subnet that sends Access Server's client subnets (`172.27.224.0/20`, `172.27.240.0/20`) to the VM, so other VMs in the VNet can reach VPN clients
- The VM, with IP forwarding enabled on its NIC

## Configuration

| Variable | Default | Description |
| --- | --- | --- |
| `admin_allowed_cidrs` | (required) | Who can reach the admin UI on TCP 943. |
| `vpn_allowed_cidrs` | `["0.0.0.0/0"]` | Who can reach TCP 443 and UDP 1194. |
| `subscription_id` | `null` | Or export `ARM_SUBSCRIPTION_ID`. |
| `location` | `westus2` | Azure region. |
| `vm_size` | `Standard_B2s` | VM size. |
| `ovpnadmin_username` | `openvpn` | Admin UI user; the password is generated. |
| `accept_marketplace_terms` | `false` | Accept the image terms with Terraform. |
| `ssh_public_key_file` / `ssh_allowed_cidrs` | `null` / `[]` | Optional SSH access. |

The admin password lives in Terraform state and in the VM's custom data. Change it in the admin UI after first login if that bothers you.
