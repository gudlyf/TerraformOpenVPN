# TerraformOpenVPN
Terraform scripts to create a quick OpenVPN server in the cloud (AWS, Azure, Google (GCP), more to come). Can be trivially modified to work with other cloud providers.

## Steps for use

1. [Download Terraform](https://www.terraform.io/downloads.html).
2. For AWS, be sure your AWS profile is setup (i.e., `$HOME/.aws/config`).
3. For GCP, be sure to generate your `account.json` from [Google Application Default Credentials](https://developers.google.com/identity/protocols/application-default-credentials) or, more easily, simply login with `gcloud auth application-default login`.
4. For Azure, be sure you have the Azure CLI installed and complete an `az login`
5. Create your SSH keys:

    `cd TerraformOpenVPN`

    `ssh-keygen -N '' -f ./certs/ovpn`

6. Edit your own `cert_details` (use `cert_details.sample` as template)
7. In the cloud provider you're using, edit the region in `variables.tf` as needed (default is Canada).
8. For Azure it will restrict SSH and VPN to your public ip by default, if otherwise needed set variables 'restrict_vpn' or 'restrict_ssh' in `variables.tf`.
9. For GCP, be sure you've created a new project and noted it in `variables.tf`.
10. cd to the cloud provider directory and perform a `terraform apply`.
11. The new `.ovpn` file will be copied from new instance into `cert_details`. Open with your OpenVPN client.

## To Do

- (AWS/GCP) Flag for "only allow this IP to connect" to either SSH and/or OpenVPN.
- Finish `fail2ban` configuration.
- Better use of variables and file hierarchy to allow for a single variables file and one place to execute the `apply` command.
- Enable this repository to be used as a module.
- Fix Azure implementation to use API/metadata to retrieve external IP.
