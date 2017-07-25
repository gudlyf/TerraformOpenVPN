# TerraformAWSOpenVPN
Terraform scripts to create a quick OpenVPN server in AWS

Create your SSH keys first:

ssh-keygen -N '' -f ./certs/ovpn

Edit your own 'cert_details' (use 'cert_details.sample' as template)

terraform plan

terraform apply
