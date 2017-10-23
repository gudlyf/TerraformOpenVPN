# TerraformOpenVPN
Terraform scripts to create a quick OpenVPN server in the cloud (AWS, Google (GCP), more to come). Can be trivially modified to work with other cloud providers.

## Steps for use

### AWS

1. [Download Terraform](https://www.terraform.io/downloads.html).
2. Be sure your AWS profile is setup (i.e., `$HOME/.aws/config`).
3. Create your SSH keys:

`cd TerraformOpenVPN`

`ssh-keygen -N '' -f ./certs/ovpn`

4. Edit your own `cert_details` (use `cert_details.sample` as template)
5. Customize the region in `variables.tf` as needed (default is `ca-central-1`).
6. `terraform plan && terraform apply`
7. New `.ovpn` file will be copied from new instance. Open with your OpenVPN client.

### Google Cloud Platform (GCP)

Coming soon...

## To Do

- Flag for "only allow this IP to connect" to either SSH and/or OpenVPN
- Finish `fail2ban` configuration
- Finish GCP client download capability
- Add MS Azure
