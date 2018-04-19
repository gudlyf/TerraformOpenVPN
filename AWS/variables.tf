variable "profile" {}

variable "region" {
  default = "ca-central-1"
}

variable "private_key_file" {
  default = "../certs/ovpn"
}

variable "public_key_file" {
  default = "../certs/ovpn.pub"
}

variable "client_config_path" {
  default = "../client_configs"
}

variable "client_config_name" {
  default = "aws-ovpn-client"
}

variable "cert_details" {
  default = "../cert_details"
}
