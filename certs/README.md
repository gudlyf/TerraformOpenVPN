# certs

Optional. Put an SSH key pair here if you want SSH access to the VPN server for troubleshooting:

```sh
ssh-keygen -t ed25519 -N '' -f certs/ovpn
```

Then set `ssh_public_key_file = "../certs/ovpn.pub"` and `ssh_allowed_cidrs` in your `terraform.tfvars`, and connect with `ssh -i certs/ovpn ubuntu@<public_ip>`.

OpenVPN certificates are not stored here; Terraform generates them. Everything in this directory except this README is git-ignored.
