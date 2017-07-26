# TerraformAWSOpenVPN
Terraform scripts to create a quick OpenVPN server in AWS. Can be trivially modified to work with other cloud providers.

### Steps for use:

1. [Download Terraform](https://www.terraform.io/downloads.html).
2. Be sure your AWS profile is setup (i.e., `$HOME/.aws/config`).
3. Create your SSH keys:

`cd TerraformAWSOpenVPN`
`ssh-keygen -N '' -f ./certs/ovpn`

4. Edit your own `cert_details` (use `cert_details.sample` as template)
5. Customize the region in `variables.tf` as needed (default is `ca-central-1`).
6. `terraform plan && terraform apply`
7. New `.ovpn` file will be copied from new instance. Open with your OpenVPN client.
