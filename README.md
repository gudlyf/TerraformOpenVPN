# TerraformOpenVPN
Terraform scripts to create a quick OpenVPN server in the cloud (AWS, Google (GCP), more to come). Can be trivially modified to work with other cloud providers.

## Steps for use

1. [Download Terraform](https://www.terraform.io/downloads.html).
2. For AWS, be sure your AWS profile is setup (i.e., `$HOME/.aws/config`).
3. For GCP, be sure to generate your `account.json` from [Google Application Default Credentials](https://developers.google.com/identity/protocols/application-default-credentials)
4. For Azure, be sure you have the Azure CLI installed and complete an `az login`
5. Create your SSH keys:

    `cd TerraformOpenVPN`

    `ssh-keygen -N '' -f ./certs/ovpn`

6. Edit your own `cert_details` (use `cert_details.sample` as template)
7. In the cloud provider you're using, edit the region in `variables.tf` as needed (default is Canada).
8. cd to the cloud provider directory and perform a `terraform plan && terraform apply`
9. The new `.ovpn` file will be copied from new instance (GCP coming soon -- for now you must SSH in and manually grab it). Open with your OpenVPN client.

## To Do

- Flag for "only allow this IP to connect" to either SSH and/or OpenVPN
- Finish `fail2ban` configuration
- Finish GCP client download capability
- Better use of variables and file hierarchy to allow for a single variables file and one place to execute the `apply` command
