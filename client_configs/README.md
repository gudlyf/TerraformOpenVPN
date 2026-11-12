# client_configs

`terraform apply` writes one `.ovpn` profile per client here, named `<cloud>-<client>.ovpn` (for example `aws-client.ovpn`). Import it into OpenVPN Connect, Tunnelblick or `openvpn --config`.

Each profile contains the client's private key. They're created with mode `0600`, git-ignored, and deleted by `terraform destroy`.

If you lose a file, Terraform can recreate it with `terraform apply`, or print it with `terraform output -json client_configs`.
